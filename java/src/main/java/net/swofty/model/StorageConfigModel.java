package net.swofty.model;

/**
 * storage { ... } block: the persistence backend, the write-behind flush
 * cadence in ticks, and (1.10.0 §1) the multi-server topology — {@code mode},
 * the {@code on_handoff_failure} policy and the optional {@code coordinator}.
 * At most one block across all scripts.
 *
 * <p>{@code mode} is {@code "standalone"} (the default, and what every script
 * written before 1.10.0 gets) or {@code "network"}. Standalone is the historical
 * behaviour, unchanged in every respect.
 */
public record StorageConfigModel(
        StorageBackendModel backend,
        int flushTicks,
        String mode,
        HandoffFailureModel handoffFailure,
        CoordinatorModel coordinator) {

    /** Default flush cadence: 30 seconds. */
    public static final int DEFAULT_FLUSH_TICKS = 600;

    /** The default topology: one server, today's write-behind semantics. */
    public static final String MODE_STANDALONE = "standalone";

    /** Multi-server topology: session ownership + replicated globals. */
    public static final String MODE_NETWORK = "network";

    public StorageConfigModel {
        mode = mode == null || mode.isBlank() ? MODE_STANDALONE : mode;
    }

    /**
     * Backwards-compatible shape: backend + flush cadence, standalone topology.
     * Every pre-1.10.0 construction site keeps working through this.
     */
    public StorageConfigModel(StorageBackendModel backend, int flushTicks) {
        this(backend, flushTicks, MODE_STANDALONE, null, null);
    }

    /** Engine default when no script declares a storage block. */
    public static StorageConfigModel defaults() {
        return new StorageConfigModel(StorageBackendModel.files("swoftlang-data"),
                DEFAULT_FLUSH_TICKS);
    }

    /** Whether this config selects the multi-server topology. */
    public boolean isNetwork() {
        return MODE_NETWORK.equalsIgnoreCase(mode);
    }

    /** The handoff-failure policy, defaulting to a kick. */
    public HandoffFailureModel handoffFailureOrDefault() {
        return handoffFailure != null ? handoffFailure : HandoffFailureModel.defaultKick();
    }
}
