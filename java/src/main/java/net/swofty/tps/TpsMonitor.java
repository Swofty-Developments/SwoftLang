package net.swofty.tps;

import net.minestom.server.MinecraftServer;
import net.minestom.server.event.EventDispatcher;
import net.minestom.server.event.server.ServerTickMonitorEvent;

/**
 * TPS introspection (design 6B/6D): Minestom has no Bukkit-style TPS, so
 * a ServerTickMonitorEvent listener records every tick's time into a
 * fixed ring buffer (5 minutes at 20 tps). tps() reads the 1-minute
 * window, averageTps() the 5-minute window; mspt() is the 1-minute mean
 * tick time. A TpsChangeEvent fires when the integer TPS bucket of the
 * 1-minute value changes.
 */
public final class TpsMonitor {
    /** 5 minutes at 20 tps. */
    static final int CAPACITY = 5 * 60 * 20;
    private static final int ONE_MINUTE_TICKS = 60 * 20;
    private static final double TICK_MILLIS = 50.0;

    private final double[] tickTimes = new double[CAPACITY];
    /** total ticks recorded (head = count % CAPACITY). */
    private long count = 0;

    private int lastBucket = 20;

    private static final TpsMonitor INSTANCE = new TpsMonitor();
    private static volatile boolean listening = false;

    public static TpsMonitor instance() {
        return INSTANCE;
    }

    /** Wire the ServerTickMonitorEvent listener (engine register). */
    public static void init() {
        if (listening) {
            return;
        }
        listening = true;
        try {
            MinecraftServer.getGlobalEventHandler().addListener(
                    ServerTickMonitorEvent.class,
                    event -> INSTANCE.record(event.getTickMonitor().getTickTime()));
        } catch (Throwable t) {
            listening = false;
            System.err.println("[tps] monitor not started (no server): " + t);
        }
    }

    /** Record one tick's time in milliseconds. Fires TpsChange on bucket move. */
    public synchronized void record(double tickTimeMillis) {
        tickTimes[(int) (count % CAPACITY)] = tickTimeMillis;
        count++;

        int bucket = (int) Math.floor(tps());
        if (bucket != lastBucket) {
            int past = lastBucket;
            lastBucket = bucket;
            dispatchChange(past, bucket);
        }
    }

    private void dispatchChange(int past, int current) {
        try {
            EventDispatcher.call(new TpsChangeEvent(past, current, tps()));
        } catch (Throwable t) {
            // serverless harness: no event system
        }
    }

    /** Reset all samples (harness). */
    public synchronized void reset() {
        count = 0;
        lastBucket = 20;
    }

    /**
     * TPS over the last window ticks: each tick costs max(tickTime, 50)ms
     * of wall time (the scheduler sleeps the remainder of the 50ms
     * budget), so tps = windowSize * 1000 / totalWallMillis, capped at 20.
     */
    private double tpsOver(int windowTicks) {
        int available = (int) Math.min(count, CAPACITY);
        if (available == 0) {
            return 20.0;
        }
        int window = Math.min(windowTicks, available);
        double totalMillis = 0;
        for (int i = 0; i < window; i++) {
            long index = (count - 1 - i) % CAPACITY;
            totalMillis += Math.max(tickTimes[(int) index], TICK_MILLIS);
        }
        return Math.min(20.0, window * 1000.0 / totalMillis);
    }

    /** 1-minute TPS. */
    public synchronized double tps() {
        return tpsOver(ONE_MINUTE_TICKS);
    }

    /** 5-minute TPS. */
    public synchronized double averageTps() {
        return tpsOver(CAPACITY);
    }

    /** Mean raw tick time (ms) over the last minute. */
    public synchronized double mspt() {
        int available = (int) Math.min(count, CAPACITY);
        if (available == 0) {
            return 0.0;
        }
        int window = Math.min(ONE_MINUTE_TICKS, available);
        double total = 0;
        for (int i = 0; i < window; i++) {
            long index = (count - 1 - i) % CAPACITY;
            total += tickTimes[(int) index];
        }
        return total / window;
    }

    /**
     * TPS around N seconds ago: the 20-tick (1s) slice ending N seconds
     * back in the ring; none-ish 20.0 when the buffer does not reach.
     */
    public synchronized double tpsAt(int secondsAgo) {
        int offset = secondsAgo * 20;
        int available = (int) Math.min(count, CAPACITY);
        if (offset + 20 > available) {
            return 20.0;
        }
        double totalMillis = 0;
        for (int i = offset; i < offset + 20; i++) {
            long index = (count - 1 - i) % CAPACITY;
            totalMillis += Math.max(tickTimes[(int) index], TICK_MILLIS);
        }
        return Math.min(20.0, 20 * 1000.0 / totalMillis);
    }

    /** Classic Essentials-style colored TPS string ("§a19.97"). */
    public static String colored(double tps) {
        double rounded = Math.round(tps * 100.0) / 100.0;
        String color = rounded >= 18.0 ? "§a" : rounded >= 15.0 ? "§e" : "§c";
        String number = rounded == Math.rint(rounded)
                ? String.valueOf((long) rounded)
                : String.valueOf(rounded);
        return color + ((rounded >= 20.0) ? "*" + number : number);
    }

    public String tpsString() {
        return colored(tps());
    }

    public String averageTpsString() {
        return colored(averageTps());
    }
}
