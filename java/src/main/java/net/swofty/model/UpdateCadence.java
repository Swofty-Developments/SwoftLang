package net.swofty.model;

/**
 * update: every N ticks|seconds (normalized to ticks by the compiler) or
 * manual
 */
public record UpdateCadence(Kind kind, int ticks) {
    public enum Kind {
        TICKS,
        MANUAL
    }

    public static UpdateCadence everyTicks(int ticks) {
        return new UpdateCadence(Kind.TICKS, ticks);
    }

    public static UpdateCadence manual() {
        return new UpdateCadence(Kind.MANUAL, 0);
    }
}
