package net.swofty.persist;

import java.io.File;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.LinkedHashMap;
import java.util.Map;

import com.google.gson.JsonElement;
import com.google.gson.JsonParser;

/**
 * SQLite backend (org.xerial:sqlite-jdbc): a single table
 * swoft_persist(var, key, value TEXT, PRIMARY KEY(var, key)) with scalar
 * values stored as JSON text. One connection, synchronized access.
 */
public final class SqliteStorage implements SwoftStorage {
    private final Connection connection;

    public SqliteStorage(String path) {
        try {
            File parent = new File(path).getAbsoluteFile().getParentFile();
            if (parent != null) {
                parent.mkdirs();
            }
            connection = DriverManager.getConnection("jdbc:sqlite:" + path);
            try (Statement statement = connection.createStatement()) {
                statement.executeUpdate("CREATE TABLE IF NOT EXISTS swoft_persist ("
                        + "var TEXT NOT NULL, key TEXT NOT NULL, value TEXT NOT NULL, "
                        + "PRIMARY KEY (var, key))");
            }
        } catch (SQLException e) {
            throw new RuntimeException("cannot open sqlite database " + path
                    + ": " + e.getMessage(), e);
        }
    }

    @Override
    public synchronized Map<String, JsonElement> loadAll(String var) {
        Map<String, JsonElement> rows = new LinkedHashMap<>();
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT key, value FROM swoft_persist WHERE var = ?")) {
            statement.setString(1, var);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) {
                    PersistStore.putParsedRow(rows, var,
                            result.getString(1), result.getString(2));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("sqlite load failed for '" + var
                    + "': " + e.getMessage(), e);
        }
        return rows;
    }

    @Override
    public synchronized void writeBatch(String var, Map<String, JsonElement> dirty) {
        try {
            connection.setAutoCommit(false);
            try (PreparedStatement statement = connection.prepareStatement(
                    "INSERT OR REPLACE INTO swoft_persist (var, key, value) VALUES (?, ?, ?)")) {
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
                connection.rollback();
            } catch (SQLException ignored) {
            }
            throw new RuntimeException("sqlite write failed for '" + var
                    + "': " + e.getMessage(), e);
        } finally {
            try {
                connection.setAutoCommit(true);
            } catch (SQLException ignored) {
            }
        }
    }

    @Override
    public synchronized void close() {
        try {
            connection.close();
        } catch (SQLException e) {
            System.err.println("Warning: closing sqlite persistence failed: " + e.getMessage());
        }
    }
}
