package net.swofty.tasks;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Point;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Entity;
import net.minestom.server.event.GlobalEventHandler;
import net.minestom.server.event.entity.EntityDespawnEvent;
import net.minestom.server.event.player.PlayerBlockBreakEvent;
import net.minestom.server.event.player.PlayerBlockPlaceEvent;
import net.minestom.server.event.player.PlayerDisconnectEvent;
import net.minestom.server.instance.Instance;
import net.swofty.ScriptError;
import net.swofty.blocks.BlockValue;
import net.swofty.displays.SwoftDisplay;
import net.swofty.players.OfflinePlayerValue;
import net.swofty.props.NoneValue;
import net.swofty.sched.ScheduleHandle;

/**
 * First-class per-object task registry (W-tasks): the {@code <obj>.tasks.<id>}
 * namespace, exactly parallel to {@code <obj>.tags.<key>} but the values are
 * running schedules rather than freeform NBT.
 *
 * <p>A task associates a named {@link ScheduleHandle} (from a {@code schedule
 * ...} expression) with an owning object under a script-chosen id. Tasks are
 * keyed by <b>owner identity</b> — player/entity/mob/display/npc/hologram by
 * entity UUID, offline player by UUID, and a {@code block_at(location)} block by
 * its world position — never by object reference, so the same live entity or
 * block position always resolves to the same task bucket.
 *
 * <p>Lifecycle: every task auto-cancels when its owner goes away —
 * <ul>
 *   <li>an entity despawns ({@link EntityDespawnEvent}) — covers script mobs,
 *       plain entities, display entities (holograms), and npc fake-players,
 *       since removing any of those despawns its backing entity;</li>
 *   <li>a player disconnects ({@link PlayerDisconnectEvent});</li>
 *   <li>the block at a bound position is broken or replaced — hooked both on the
 *       vanilla {@link PlayerBlockBreakEvent}/{@link PlayerBlockPlaceEvent} path
 *       and on the imperative {@code place}/{@code remove block} statements.</li>
 * </ul>
 * and everything is wiped on hot-reload teardown / shutdown via
 * {@link #clearAll()} so no owner identity leaks stale schedules across a
 * reload.
 */
public final class TaskRegistry {
    /** owner-identity key -> (task id -> live schedule handle). */
    private static final Map<String, Map<String, ScheduleHandle>> TASKS =
            new ConcurrentHashMap<>();

    private static boolean initialized = false;

    private TaskRegistry() {
    }

    /** Wire the auto-cancel listeners once; safe to call on every reload. */
    public static synchronized void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        GlobalEventHandler handler = MinecraftServer.getGlobalEventHandler();
        handler.addListener(EntityDespawnEvent.class,
                event -> cancelEntity(event.getEntity()));
        handler.addListener(PlayerDisconnectEvent.class,
                event -> cancelEntity(event.getPlayer()));
        // a block broken or replaced by a player drops every task bound to that
        // position (the imperative place/remove statements do the same directly)
        handler.addListener(PlayerBlockBreakEvent.class,
                event -> cancelBlock(event.getInstance(), event.getBlockPosition()));
        handler.addListener(PlayerBlockPlaceEvent.class,
                event -> cancelBlock(event.getInstance(), event.getBlockPosition()));
    }

    // ------------------------------------------------------------------
    // owner identity
    // ------------------------------------------------------------------

    /**
     * The stable identity key for a task owner, or a {@link ScriptError} for a
     * value that carries no task registry (an item, a bare {@code block("id")}
     * with no position, or none).
     */
    public static String identity(Object owner) {
        if (owner instanceof Entity entity) {
            return "e:" + entity.getUuid();
        }
        if (owner instanceof SwoftDisplay display) {
            return "e:" + display.entity().getUuid();
        }
        if (owner instanceof OfflinePlayerValue offline) {
            return "e:" + offline.uuid();
        }
        if (owner instanceof BlockValue block) {
            if (!block.hasPosition()) {
                throw new ScriptError("this block has no position; a task can only bind to "
                        + "block_at(location)");
            }
            return blockKey(block.instance(), block.position());
        }
        if (owner == null || NoneValue.isNone(owner)) {
            throw new ScriptError("cannot attach a task to none");
        }
        throw new ScriptError(owner.getClass().getSimpleName() + " has no task registry; "
                + ".tasks is only available on Player, Mob, Entity, Npc, Hologram, and "
                + "block_at(location)");
    }

    private static String blockKey(Instance instance, Pos pos) {
        String world = instance != null ? instance.getUuid().toString() : "?";
        return "b:" + world + ":" + pos.blockX() + ":" + pos.blockY() + ":" + pos.blockZ();
    }

    // ------------------------------------------------------------------
    // script surface: set / cancel / read / is-running
    // ------------------------------------------------------------------

    /**
     * Associate {@code handle} with {@code owner} under {@code id}, cancelling
     * (and replacing) any prior task already held under the same id first.
     */
    public static void set(Object owner, String id, ScheduleHandle handle) {
        String key = identity(owner);
        Map<String, ScheduleHandle> bucket =
                TASKS.computeIfAbsent(key, k -> new ConcurrentHashMap<>());
        ScheduleHandle previous = bucket.put(id, handle);
        if (previous != null && previous != handle) {
            previous.cancel();
        }
    }

    /** Cancel and drop the task under {@code id} (no-op if absent). */
    public static void cancel(Object owner, String id) {
        Map<String, ScheduleHandle> bucket = TASKS.get(identity(owner));
        if (bucket == null) {
            return;
        }
        ScheduleHandle handle = bucket.remove(id);
        if (handle != null) {
            handle.cancel();
        }
        if (bucket.isEmpty()) {
            TASKS.remove(identity(owner), bucket);
        }
    }

    /**
     * The live schedule handle under {@code id}, or null when absent or already
     * finished. A finished handle is lazily evicted so {@code <obj>.tasks.<id>}
     * reads {@code none} once a bounded schedule has run out.
     */
    public static ScheduleHandle get(Object owner, String id) {
        Map<String, ScheduleHandle> bucket = TASKS.get(identity(owner));
        if (bucket == null) {
            return null;
        }
        ScheduleHandle handle = bucket.get(id);
        if (handle == null) {
            return null;
        }
        if (!handle.isRunning()) {
            bucket.remove(id, handle);
            if (bucket.isEmpty()) {
                TASKS.remove(identity(owner), bucket);
            }
            return null;
        }
        return handle;
    }

    /** Whether a live task is running under {@code id}. */
    public static boolean isRunning(Object owner, String id) {
        ScheduleHandle handle = get(owner, id);
        return handle != null && handle.isRunning();
    }

    // ------------------------------------------------------------------
    // lifecycle auto-cancel
    // ------------------------------------------------------------------

    /** Cancel and drop every task bound to an entity (despawn/disconnect). */
    public static void cancelEntity(Entity entity) {
        if (entity != null) {
            cancelKey("e:" + entity.getUuid());
        }
    }

    /** Cancel and drop every task bound to a block position (remove/replace). */
    public static void cancelBlock(Instance instance, Point position) {
        if (instance == null || position == null) {
            return;
        }
        cancelKey("b:" + instance.getUuid() + ":" + position.blockX() + ":"
                + position.blockY() + ":" + position.blockZ());
    }

    private static void cancelKey(String key) {
        Map<String, ScheduleHandle> bucket = TASKS.remove(key);
        if (bucket != null) {
            for (ScheduleHandle handle : bucket.values()) {
                handle.cancel();
            }
        }
    }

    /** Cancel every task everywhere and clear the registry (reload/shutdown). */
    public static void clearAll() {
        for (Map<String, ScheduleHandle> bucket : TASKS.values()) {
            for (ScheduleHandle handle : bucket.values()) {
                handle.cancel();
            }
        }
        TASKS.clear();
    }

    /** Total number of owners that currently hold at least one task. */
    public static int trackedOwners() {
        return TASKS.size();
    }
}
