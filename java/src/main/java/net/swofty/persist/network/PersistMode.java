package net.swofty.persist.network;

import net.swofty.model.StorageConfigModel;

/**
 * Persistence topology (design 1.10.0 §1), read off the emitted storage block.
 *
 * <p>{@link #STANDALONE} is the default and MUST behave byte-identically to
 * pre-1.10.0: one server, write-behind cache, the {@code flush:} timer as the
 * durability mechanism. Every network code path in this package is gated behind
 * {@link #NETWORK}, so a standalone program never allocates a lease manager, a
 * replica, or a broadcast channel and never takes a different branch inside
 * {@code PersistStore.get}/{@code set}.
 */
public enum PersistMode {
    STANDALONE,
    NETWORK;

    /** The mode of a (possibly null) storage config; null/unknown = standalone. */
    public static PersistMode of(StorageConfigModel config) {
        return config != null && config.isNetwork() ? NETWORK : STANDALONE;
    }

    public boolean isNetwork() {
        return this == NETWORK;
    }
}
