package net.swofty.model;

/**
 * storage { backend: ... } declaration. kind is files|sqlite|mysql|mongodb;
 * path is the files directory or sqlite database file, host/port/database/
 * user/password configure mysql, uri is the mongodb connection string.
 */
public record StorageBackendModel(
        String kind,
        String path,
        String host,
        int port,
        String database,
        String user,
        String password,
        String uri) {

    public static StorageBackendModel files(String path) {
        return new StorageBackendModel("files", path, null, 0, null, null, null, null);
    }

    public static StorageBackendModel sqlite(String path) {
        return new StorageBackendModel("sqlite", path, null, 0, null, null, null, null);
    }
}
