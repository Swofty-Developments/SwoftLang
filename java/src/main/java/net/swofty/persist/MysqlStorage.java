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
