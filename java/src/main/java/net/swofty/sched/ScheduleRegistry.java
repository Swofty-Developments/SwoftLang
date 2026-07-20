package net.swofty.sched;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Named-schedule registry (scheduler v2): {@code every ... as "name"} and
 * {@code schedule ... as "name"} publish their handle here so scripts can
 * {@code cancel schedule "name"} or test {@code is_running("name")}.
 *
 * <p>Re-registering a live name replaces it: the previously running schedule
 * is cancelled and the new one takes the slot. The registry is wiped —
 * cancelling every live handle — on engine reload and server shutdown.
 */
public final class ScheduleRegistry {
    private static final Map<String, ScheduleHandle> NAMED = new ConcurrentHashMap<>();
    /**
     * Every live schedule handle — named AND anonymous — so a reload/shutdown
     * {@code cancelAll()} tears down anonymous {@code every}/{@code schedule}/
     * {@code repeat} loops too (which never land in {@link #NAMED}), instead of
     * leaking them across a hot reload where they'd keep firing OLD code.
     */
    private static final Set<ScheduleHandle> ALL = ConcurrentHashMap.newKeySet();

    private ScheduleRegistry() {
    }

    /**
     * Record a live handle (called for every schedule at start, named or not)
     * so {@link #cancelAll()} can reach anonymous loops. The handle drops out
     * via {@link #release(ScheduleHandle)} when it finishes.
     */
    public static void track(ScheduleHandle handle) {
        if (handle != null) {
            ALL.add(handle);
        }
    }

    /**
     * Publish {@code handle} under {@code name}, cancelling and replacing any
     * live schedule already holding that name.
     */
    public static void register(String name, ScheduleHandle handle) {
        if (name == null) {
            return;
        }
        handle.setName(name);
        ScheduleHandle previous = NAMED.put(name, handle);
        if (previous != null && previous != handle) {
            previous.cancel();
        }
    }

    /** The handle currently registered under {@code name}, or null. */
    public static ScheduleHandle lookup(String name) {
        return name == null ? null : NAMED.get(name);
    }

    /**
     * Cancel the schedule registered under {@code name} (if any) and drop it
     * from the registry. Returns true if a live handle was cancelled.
     */
    public static boolean cancel(String name) {
        ScheduleHandle handle = name == null ? null : NAMED.remove(name);
        if (handle == null) {
            return false;
        }
        boolean wasRunning = handle.isRunning();
        handle.cancel();
        return wasRunning;
    }

    /**
     * Drop {@code handle} from its name slot once it finishes, but only if it
     * is still the registered occupant (a later re-register must not be
     * evicted by an older handle's teardown).
     */
    static void release(ScheduleHandle handle) {
        ALL.remove(handle);
        String name = handle.name();
        if (name != null) {
            NAMED.remove(name, handle);
        }
    }

    /**
     * Cancel every live schedule — named and anonymous — and clear the
     * registry (reload/shutdown). Draining {@link #ALL} covers the anonymous
     * {@code every}/{@code schedule}/{@code repeat} loops that {@link #NAMED}
     * never held, so a hot reload leaves no old-code loop still firing.
     */
    public static void cancelAll() {
        List<ScheduleHandle> handles = new ArrayList<>(ALL);
        ALL.clear();
        NAMED.clear();
        for (ScheduleHandle handle : handles) {
            handle.cancel();
        }
    }

    /** Live named-schedule count (diagnostics/tests). */
    public static int size() {
        return NAMED.size();
    }

    /**
     * Total live schedule count — named AND anonymous (diagnostics/tests).
     * A hot-reload smoke asserts this stays constant across reloads to prove
     * no {@code every}/{@code schedule}/{@code repeat} loop is doubled up or
     * leaked (the double-tick regression).
     */
    public static int liveCount() {
        return ALL.size();
    }

    /** Snapshot of every live handle (diagnostics/tests). */
    public static java.util.List<ScheduleHandle> liveHandles() {
        return new ArrayList<>(ALL);
    }
}
