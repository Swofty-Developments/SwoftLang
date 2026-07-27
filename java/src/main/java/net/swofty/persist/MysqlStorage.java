package net.swofty.persist;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.LinkedHashMap;
import java.util.Map;

import com.google.gson.JsonElement;

/**
 * MySQL backend (com.mysql:mysql-connector-j): same swoft_persist schema
 * as sqlite (var/key as VARCHAR so they can form the primary key, value
 * as JSON TEXT). A single connection guarded by synchronized methods —
 * the flush cadence makes a pool unnecessary. MySQL drops idle
 * connections at wait_timeout (8h default), so every operation validates
 * the connection first and reopens it when dead; a failed write is
 * re-marked dirty by PersistStore and retried next cycle, so writes
 * resume as soon as the server is reachable again.
 */
public final class MysqlStorage implements SwoftStorage {
    private static final int VALIDATE_TIMEOUT_SECONDS = 2;

    private final String url;
    private final String user;
    private final String password;
    private Connection connection;

    public MysqlStorage(String host, int port, String database, String user, String password) {
        this.url = "jdbc:mysql://" + host + ":" + port + "/" + database;
        this.user = user;
        this.password = password;
        try {
            connect();
        } catch (SQLException e) {
            throw new RuntimeException("cannot connect to mysql at " + url
                    + ": " + e.getMessage(), e);
        }
    }

    /** Open a fresh connection and make sure the schema exists. */
    private void connect() throws SQLException {
        connection = DriverManager.getConnection(url, user, password);
        try (Statement statement = connection.createStatement()) {
            statement.executeUpdate("CREATE TABLE IF NOT EXISTS swoft_persist ("
                    + "`var` VARCHAR(255) NOT NULL, `key` VARCHAR(255) NOT NULL, "
                    + "`value` TEXT NOT NULL, PRIMARY KEY (`var`, `key`))");
        }
    }

    /**
     * Reopen the connection if the server dropped it (wait_timeout,
     * restart, network blip). Callers hold the monitor, so the field swap
     * is safe; a failed reconnect propagates and the caller's operation
     * fails this cycle only.
     */
    private void ensureConnection() throws SQLException {
        boolean valid;
        try {
            valid = connection != null && connection.isValid(VALIDATE_TIMEOUT_SECONDS);
        } catch (SQLException e) {
            valid = false;
        }
        if (valid) {
            return;
        }
        System.err.println("Warning: mysql connection to " + url
                + " is dead - reconnecting");
        closeQuietly();
        connect();
        System.err.println("mysql connection to " + url + " re-established");
    }

    private void closeQuietly() {
        if (connection == null) {
            return;
        }
        try {
            connection.close();
        } catch (SQLException ignored) {
        }
        connection = null;
    }

    @Override
    public synchronized Map<String, JsonElement> loadAll(String var) {
        Map<String, JsonElement> rows = new LinkedHashMap<>();
        try {
            ensureConnection();
            try (PreparedStatement statement = connection.prepareStatement(
                    "SELECT `key`, `value` FROM swoft_persist WHERE `var` = ?")) {
                statement.setString(1, var);
                try (ResultSet result = statement.executeQuery()) {
                    while (result.next()) {
                        PersistStore.putParsedRow(rows, var,
                                result.getString(1), result.getString(2));
                    }
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("mysql load failed for '" + var
                    + "': " + e.getMessage(), e);
        }
        return rows;
    }

    @Override
    public synchronized JsonElement load(String var, String key) {
        Map<String, JsonElement> rows = new LinkedHashMap<>();
        try {
            ensureConnection();
            try (PreparedStatement statement = connection.prepareStatement(
                    "SELECT `key`, `value` FROM swoft_persist WHERE `var` = ? AND `key` = ?")) {
                statement.setString(1, var);
                statement.setString(2, key);
                try (ResultSet result = statement.executeQuery()) {
                    if (result.next()) {
                        PersistStore.putParsedRow(rows, var,
                                result.getString(1), result.getString(2));
                    }
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("mysql load failed for '" + var
                    + "[" + key + "]': " + e.getMessage(), e);
        }
        return rows.get(key);
    }

    @Override
    public synchronized void writeBatch(String var, Map<String, JsonElement> dirty) {
        try {
            ensureConnection();
            connection.setAutoCommit(false);
            try (PreparedStatement statement = connection.prepareStatement(
                    "INSERT INTO swoft_persist (`var`, `key`, `value`) VALUES (?, ?, ?) "
                            + "ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)")) {
                for (Map.Entry<String, JsonElement> entry : dirty.entrySet()) {
                    statement.setString(1, var);
                    statement.setString(2, entry.getKey());
                    statement.setString(3, entry.getValue().toString());
                    statement.addBatch();
                }
                statement.executeBatch();
            }
            connection.commit();
        } catch (SQLException e) {
            try {
                if (connection != null) {
                    connection.rollback();
                }
            } catch (SQLException ignored) {
            }
            throw new RuntimeException("mysql write failed for '" + var
                    + "': " + e.getMessage(), e);
        } finally {
            try {
                if (connection != null) {
                    connection.setAutoCommit(true);
                }
            } catch (SQLException ignored) {
            }
        }
    }

    /**
     * The real conditional write (1.10.0 §2.1/§2.2). {@code (var, key)} is the
     * primary key, so both statements below are single-row atomic operations —
     * the UPDATE matches only if nobody changed the row since we read it, and the
     * INSERT can only succeed for one racer when several try to create it.
     *
     * <p>The comparison is {@code BINARY} so it is byte-exact rather than subject
     * to the column's collation: a lease owner differing only in case is a
     * different server.
     */
    @Override
    public synchronized CasOutcome compareAndSet(String var, String key, String expected,
            String next) {
        String stored = next == null ? "null" : next;
        try {
            ensureConnection();
            if (expected != null) {
                try (PreparedStatement statement = connection.prepareStatement(
                        "UPDATE swoft_persist SET `value` = ? WHERE `var` = ? AND `key` = ?"
                                + " AND `value` = BINARY ?")) {
                    statement.setString(1, stored);
                    statement.setString(2, var);
                    statement.setString(3, key);
                    statement.setString(4, expected);
                    if (statement.executeUpdate() == 1) {
                        return new CasOutcome(true, next);
                    }
                }
                return new CasOutcome(false, readRaw(var, key));
            }
            // expected == null: the row must be absent, or hold the tombstone a
            // deletion leaves behind. Claim it in one statement that only bites
            // on those two states, so exactly one racer can win.
            try (PreparedStatement statement = connection.prepareStatement(
                    "INSERT INTO swoft_persist (`var`, `key`, `value`) VALUES (?, ?, ?)"
                            + " ON DUPLICATE KEY UPDATE `value` ="
                            + " IF(`value` = BINARY 'null', VALUES(`value`), `value`)")) {
                statement.setString(1, var);
                statement.setString(2, key);
                statement.setString(3, stored);
                statement.executeUpdate();
            }
            // ON DUPLICATE KEY UPDATE cannot report which branch it took, so the
            // read-back decides - and unlike a read-check-write-read-back it is
            // sound, because the write above is the conditional one.
            String observed = readRaw(var, key);
            if (stored.equals(observed)) {
                return new CasOutcome(true, next);
            }
            return new CasOutcome(false, observed);
        } catch (SQLException e) {
            throw new RuntimeException("mysql compare-and-set failed for '" + var
                    + "[" + key + "]': " + e.getMessage(), e);
        }
    }

    /** The row exactly as stored, or null when absent / tombstoned. */
    private String readRaw(String var, String key) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT `value` FROM swoft_persist WHERE `var` = ? AND `key` = ?")) {
            statement.setString(1, var);
            statement.setString(2, key);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) {
                    return null;
                }
                String value = result.getString(1);
                return "null".equals(value) ? null : value;
            }
        }
    }

    @Override
    public synchronized void close() {
        try {
            if (connection != null) {
                connection.close();
            }
        } catch (SQLException e) {
            System.err.println("Warning: closing mysql persistence failed: " + e.getMessage());
        }
    }
}
