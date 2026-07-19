package net.swofty.async;

/**
 * Unwinds the entire current script task, through function frames.
 * Replaces the old halted boolean, which could not unwind function calls.
 */
public final class HaltSignal extends RuntimeException {
    public HaltSignal() {
        super(null, null, false, false);
    }
}
