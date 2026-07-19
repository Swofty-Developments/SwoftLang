package net.swofty.model;

import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * Top-level {@code every 5 seconds { ... }} declaration (design 6D):
 * async-colored body started at engine boot, repeating every
 * {@code intervalTicks} after an optional initial {@code delayTicks}.
 */
public record EveryDeclModel(
        long delayTicks,
        long intervalTicks,
        String name,
        ExecuteBlock body,
        int line,
        int col) {

    /** Backward-compatible constructor for unnamed every-declarations. */
    public EveryDeclModel(long delayTicks, long intervalTicks, ExecuteBlock body,
            int line, int col) {
        this(delayTicks, intervalTicks, null, body, line, col);
    }
}
