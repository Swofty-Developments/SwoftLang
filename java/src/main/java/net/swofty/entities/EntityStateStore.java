package net.swofty.entities;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Entity;
import net.minestom.server.event.GlobalEventHandler;
import net.minestom.server.event.entity.EntityDespawnEvent;
import net.minestom.server.event.player.PlayerDisconnectEvent;

/**
 * Per-entity in-memory key/value scratch store (W-pvp foundational primitive).
 *
 * <p>This is runtime scratch memory keyed by entity UUID — deliberately
 * <b>distinct from disk persistence</b> (the {@code persistent} system) and
 * from the NBT-backed {@link EntityTagsView} {@code entity.tags.*} namespace,
 * which serializes with polar/anvil worlds. State here never touches disk; it
 * backs the ephemeral combat bookkeeping vanilla PvP needs — i-frame timers,
 * attack cooldowns, exhaustion accumulators, combat tags, last-damage
 * timestamps — all written from {@code .sw} on a tick loop.
 *
 * <p>Exposed to scripts through four builtins:
 * {@code set_state(entity, key, value)}, {@code get_state(entity, key)} →
 * optional&lt;V&gt;, {@code has_state(entity, key)} → Boolean, and
 * {@code clear_state(entity, key)}.
 *
 * <p>Lifecycle: an entity's whole state bag is auto-cleared when it despawns
 * ({@link EntityDespawnEvent}) or a player disconnects
 * ({@link PlayerDisconnectEvent}), and the entire store is wiped on hot-reload
 * teardown and shutdown ({@link #clearAll()}) so a fresh script starts clean and
 * no UUID can leak across reloads. {@link #init()} wires the two listeners once
 * (idempotent — the engine calls it on every reload).
 */
public final class EntityStateStore {

    /** entity UUID -> (key -> value). Both levels concurrency-safe. */
    private static final Map<UUID, Map<String, Object>> STATE = new ConcurrentHashMap<>();

    private static boolean initialized = false;

    private EntityStateStore() {
    }

    /** Wire the auto-clear listeners once; safe to call on every reload. */
    public static synchronized void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        GlobalEventHandler handler = MinecraftServer.getGlobalEventHandler();
        handler.addListener(EntityDespawnEvent.class, event -> clearEntity(event.getEntity()));
        handler.addListener(PlayerDisconnectEvent.class, event -> clearEntity(event.getPlayer()));
    }

    /** Store a value under key for entity (overwrites any previous value). */
    public static void set(Entity entity, String key, Object value) {
        // ConcurrentHashMap forbids null values; callers map none -> clear().
        STATE.computeIfAbsent(entity.getUuid(), uuid -> new ConcurrentHashMap<>()).put(key, value);
    }

    /** The stored value, or null if entity has no such key. */
    public static Object get(Entity entity, String key) {
        Map<String, Object> bag = STATE.get(entity.getUuid());
        return bag == null ? null : bag.get(key);
    }

    /** Whether entity has a value stored under key. */
    public static boolean has(Entity entity, String key) {
        Map<String, Object> bag = STATE.get(entity.getUuid());
        return bag != null && bag.containsKey(key);
    }

    /** Remove one key from entity's bag, dropping the bag when it empties. */
    public static void clear(Entity entity, String key) {
        Map<String, Object> bag = STATE.get(entity.getUuid());
        if (bag != null) {
            bag.remove(key);
            if (bag.isEmpty()) {
                STATE.remove(entity.getUuid());
            }
        }
    }

    /** Drop every key for one entity (despawn/disconnect auto-clear). */
    public static void clearEntity(Entity entity) {
        STATE.remove(entity.getUuid());
    }

    /** Wipe the whole store (hot-reload teardown / shutdown). */
    public static void clearAll() {
        STATE.clear();
    }

    /** Entities that currently hold at least one state key (diagnostics). */
    public static int trackedEntities() {
        return STATE.size();
    }
}
