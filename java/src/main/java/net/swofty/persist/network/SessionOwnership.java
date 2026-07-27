package net.swofty.persist.network;

import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Player;
import net.minestom.server.event.Event;
import net.minestom.server.event.EventListener;
import net.minestom.server.event.EventNode;
import net.minestom.server.event.player.AsyncPlayerConfigurationEvent;
import net.minestom.server.event.player.PlayerDisconnectEvent;
import net.swofty.persist.PersistStore;

/**
 * The join/quit hooks of design 1.10.0 §2.1 / §6: "acquire+load BEFORE join
 * handlers; save+evict+release on quit/transfer".
 *
 * <p><b>Ordering is the whole point,</b> and both halves lean on how Minestom
 * dispatches: a node runs its OWN listeners before its children, and children in
 * ascending priority order.
 * <ul>
 *   <li><b>Acquire</b> rides {@link AsyncPlayerConfigurationEvent} on the global
 *       node. That event fires off the tick threads (blocking IO is legal there),
 *       it is allowed to kick, and it strictly precedes {@code PlayerSpawnEvent}
 *       — which is what a script's {@code on join} handler listens to. So by the
 *       time any script code sees the player, the lease is held and the values
 *       are loaded, exactly as §2.1.1 promises.</li>
 *   <li><b>Release</b> rides {@link PlayerDisconnectEvent} on a child node with
 *       maximum priority, so it runs AFTER every script quit handler — a write
 *       made in {@code on quit} is still captured by the synchronous flush.</li>
 * </ul>
 *
 * <p>On a failed acquisition the player is kicked (or whatever
 * {@code on_handoff_failure} says). Under no circumstance are defaults served:
 * that is how progress gets duplicated or erased.
 */
public final class SessionOwnership {

    private static EventNode<Event> quitNode;
    private static EventListener<AsyncPlayerConfigurationEvent> acquireListener;
    private static boolean installed;

    private SessionOwnership() {
    }

    /** Wire the hooks. No-op when already installed or when there is no server. */
    public static synchronized void install(PersistStore store, NetworkRuntime runtime) {
        if (installed) {
            return;
        }
        EventNode<Event> root;
        try {
            root = MinecraftServer.getGlobalEventHandler();
        } catch (Throwable t) {
            System.err.println("[persist] no Minestom event handler yet - session"
                    + " ownership hooks are not installed (" + t + ")");
            return;
        }
        if (root == null) {
            // headless (a harness, or persistence built before MinecraftServer.init):
            // the hooks have nothing to attach to. acquireSession/releaseSession
            // still work and are what the caller must drive by hand.
            System.err.println("[persist] no Minestom event handler yet - session"
                    + " ownership hooks are not installed");
            return;
        }
        acquireListener = EventListener.of(AsyncPlayerConfigurationEvent.class,
                event -> onAcquire(store, runtime, event.getPlayer()));
        root.addListener(acquireListener);

        quitNode = EventNode.all("swoft-persist-session");
        quitNode.setPriority(Integer.MAX_VALUE);
        quitNode.addListener(PlayerDisconnectEvent.class,
                event -> onRelease(store, runtime, event.getPlayer()));
        root.addChild(quitNode);
        installed = true;
    }

    /**
     * Detach the hooks. Called only on a full shutdown / store replacement —
     * NOT on a hot reload, which must leave live sessions (and their leases)
     * exactly as they are.
     */
    public static synchronized void uninstall() {
        if (!installed) {
            return;
        }
        try {
            EventNode<Event> root = MinecraftServer.getGlobalEventHandler();
            if (acquireListener != null) {
                root.removeListener(acquireListener);
            }
            if (quitNode != null) {
                root.removeChild(quitNode);
            }
        } catch (Throwable t) {
            System.err.println("[persist] detaching session hooks failed: " + t);
        }
        acquireListener = null;
        quitNode = null;
        installed = false;
    }

    /**
     * §2.1.1 acquire-then-load, by subject key. Split out from the join listener
     * because it is the whole of the handoff and needs to be reachable without a
     * live Minestom {@code Player} — the two-server harness drives exactly this.
     *
     * @return null on success, else the reason the handoff failed (which the
     *         caller turns into {@code on_handoff_failure}). On failure NOTHING
     *         is left loaded: never serve defaults for a session we do not own.
     */
    public static String acquireSession(PersistStore store, NetworkRuntime runtime, String key) {
        long generation = runtime.leases().acquire(key);
        if (generation == LeaseManager.NO_LEASE) {
            return "the previous server has not released this session yet";
        }
        try {
            store.loadSession(key, generation);
            return null;
        } catch (Exception e) {
            // a half-loaded session is worse than no session: drop everything we
            // read, hand the lease back, and refuse the join.
            store.evictSession(key);
            runtime.leases().release(key);
            return "loading the session failed: " + e.getMessage();
        }
    }

    /**
     * §2.1.2 save-and-evict-then-release, by subject key. The order is
     * load-bearing: flush synchronously, drop the rows from memory, and only
     * then hand the lease on. A failed flush evicts but deliberately KEEPS the
     * lease, so the TTL — not another server's optimism — decides when the
     * session becomes available again.
     *
     * <p>The eviction happens a second time inside {@link LeaseManager#release},
     * after the lease is actually gone — see the note there on the write that can
     * land in the evict-to-release window.
     */
    public static void releaseSession(PersistStore store, NetworkRuntime runtime, String key) {
        try {
            store.flushSession(key);
        } catch (Exception e) {
            System.err.println("[persist] the synchronous session flush for " + key
                    + " failed: " + e.getMessage()
                    + " - the lease is held until its ttl so no other server can"
                    + " load a stale copy");
            store.evictSession(key);
            return;
        }
        store.evictSession(key);
        runtime.leases().release(key);
    }

    private static void onAcquire(PersistStore store, NetworkRuntime runtime, Player player) {
        String failure = acquireSession(store, runtime, player.getUuid().toString());
        if (failure != null) {
            runtime.applyHandoffFailure(player, failure);
        }
    }

    private static void onRelease(PersistStore store, NetworkRuntime runtime, Player player) {
        releaseSession(store, runtime, player.getUuid().toString());
    }
}
