package net.swofty.tps;

import net.minestom.server.event.Event;

/**
 * Fired by the TpsMonitor when the integer TPS bucket of the 1-minute
 * value crosses to a new integer (design 6B): past/current are the
 * buckets, tps the precise new value.
 */
public final class TpsChangeEvent implements Event {
    private final int past;
    private final int current;
    private final double tps;

    public TpsChangeEvent(int past, int current, double tps) {
        this.past = past;
        this.current = current;
        this.tps = tps;
    }

    public int getPast() {
        return past;
    }

    public int getCurrent() {
        return current;
    }

    public double getTps() {
        return tps;
    }
}
