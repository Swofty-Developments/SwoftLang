package net.swofty.reload;

import java.util.ArrayList;
import java.util.List;

/**
 * Central hot-reload teardown registry (#58).
 *
 * <p>Every runtime subsystem that creates live, program-derived state (spawned
 * entities/mobs, event &amp; packet listeners, schedulers/tasks, viewers, HUDs,
 * holograms/npcs, the reactive-instance index, the struct/nominal-type
 * registries, displays, the http server, songs, …) registers a teardown
 * callback here at load time via {@link #register}. A hot reload runs every
 * callback in <em>reverse</em> registration order ({@link #runTeardown}) so the
 * last-created subsystem is dismantled first, then clears the registry, loads
 * the new compiled program, and re-registers everything fresh (which re-arms
 * the callbacks for the next reload).
 *
 * <p>The {@link net.swofty.persist.PersistStore} is deliberately NOT a member:
 * persistent values survive a reload and the reactive-instance liveness is
 * re-derived from those surviving roots after re-registration.
 *
 * <p>Callbacks must be idempotent and must not throw fatally — a throwing
 * teardown is logged and the remaining callbacks still run, so one broken
 * subsystem can never leave the others half-torn-down (ghost handlers).
 */
public final class ReloadRegistry {

    /** A named teardown callback registered by a runtime subsystem. */
    public record Hook(String name, Runnable teardown) {
    }

    private static final List<Hook> HOOKS = new ArrayList<>();

    private ReloadRegistry() {
    }

    /**
     * Register a teardown callback under {@code name}. Called at load time by a
     * subsystem right after it wires its live state, so the reverse-order
     * teardown dismantles subsystems in last-in-first-out order.
     */
    public static synchronized void register(String name, Runnable teardown) {
        HOOKS.add(new Hook(name, teardown));
    }

    /**
     * Run every registered teardown in reverse registration order, then clear
     * the registry. A callback that throws is logged and skipped so the rest
     * still run. MUST run on the tick thread (callers hop there via
     * {@code scheduleNextTick}).
     */
    public static synchronized void runTeardown() {
        for (int i = HOOKS.size() - 1; i >= 0; i--) {
            Hook hook = HOOKS.get(i);
            try {
                hook.teardown().run();
            } catch (Throwable t) {
                System.err.println("[reload] teardown '" + hook.name()
                        + "' failed: " + t);
            }
        }
        HOOKS.clear();
    }

    /** Drop every registered callback without running it. */
    public static synchronized void clear() {
        HOOKS.clear();
    }

    /** Number of currently-registered teardown callbacks. */
    public static synchronized int size() {
        return HOOKS.size();
    }

    /** The names of the currently-registered callbacks, in registration order. */
    public static synchronized List<String> names() {
        List<String> out = new ArrayList<>(HOOKS.size());
        for (Hook hook : HOOKS) {
            out.add(hook.name());
        }
        return out;
    }
}
