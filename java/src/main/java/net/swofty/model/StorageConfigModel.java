package net.swofty.model;

/**
 * storage { ... } block: the persistence backend plus the write-behind
 * flush cadence in ticks. At most one block across all scripts.
 */
public record StorageConfigModel(StorageBackendModel backend, int flushTicks) {

    /** Default flush cadence: 30 seconds. */
    public static final int DEFAULT_FLUSH_TICKS = 600;

    /** Engine default when no script declares a storage block. */
    public static StorageConfigModel defaults() {
        return new StorageConfigModel(StorageBackendModel.files("swoftlang-data"),
                DEFAULT_FLUSH_TICKS);
    }
}
