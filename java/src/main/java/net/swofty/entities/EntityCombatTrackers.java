package net.swofty.entities;

import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.Player;
import net.minestom.server.event.GlobalEventHandler;
import net.minestom.server.event.entity.EntityDamageEvent;
import net.minestom.server.event.entity.EntityDespawnEvent;
import net.minestom.server.event.entity.EntityTickEvent;
import net.minestom.server.event.player.PlayerDisconnectEvent;
import net.minestom.server.instance.Instance;
import net.minestom.server.instance.block.Block;

/**
 * Per-entity native combat trackers for the three vanilla-PvP inputs Minestom
 * ships but does <b>not</b> expose (verified against the pinned
 * {@code 2026.07.12-26.2} jar with {@code javap}):
 *
 * <ol>
 *   <li><b>Invulnerability (i-frame) timer.</b> {@code LivingEntity} carries a
 *       {@code protected Damage lastDamage} field and {@code getLastDamageSource()}
 *       but <b>no</b> {@code getInvulnerableTime()} / tick counter, and the
 *       high-level {@code damage(...)} path does not implement the vanilla
 *       "strongest-hit-in-N-ticks" rule. We record the {@code getAliveTicks()}
 *       stamp of the most recent {@link EntityDamageEvent} and expose the
 *       countdown via {@link #invulnerableTicks(Entity)}. The vanilla window is
 *       {@value #IFRAME_WINDOW} ticks; SwoftLang only <em>provides</em> the timer
 *       and leaves honouring it to the {@code .sw} script (so custom PvP can pick
 *       its own window).</li>
 *   <li><b>Fall distance.</b> {@code Entity} exposes no {@code getFallDistance()}
 *       and holds no fall-distance field. We accumulate the downward distance an
 *       entity travels while airborne from {@link EntityTickEvent} (fires once per
 *       tick for every entity, players included) and reset it to zero on landing
 *       ({@code isOnGround()}) or while a player is flying. Read via
 *       {@link #fallDistance(Entity)} — feeds crit checks (falling + not on-ground)
 *       and fall-damage math.</li>
 * </ol>
 *
 * <p>The third status read the design asked for — <b>climbing</b> — has no meta
 * or field on Minestom either (no {@code isClimbing}, no climbing pose), so it is
 * derived positionally by {@link #isClimbing(Entity)} from the block at the
 * entity's feet rather than tracked here. ({@code is_sprinting} and {@code vehicle}
 * <em>are</em> exposed natively — {@code Entity.isSprinting()} / {@code getVehicle()}
 * — and remain plain entity properties.)
 *
 * <p>This is ephemeral runtime scratch keyed by entity UUID, exactly like
 * {@link EntityStateStore}: never touches disk, auto-cleared when an entity
 * despawns or a player disconnects, and fully wiped on hot-reload teardown /
 * shutdown ({@link #clearAll()}) so no UUID leaks across reloads. {@link #init()}
 * wires the listeners once (idempotent — called on every reload).
 */
public final class EntityCombatTrackers {

    /** Vanilla invulnerability window, in ticks (the "10-tick i-frame" rule). */
    public static final long IFRAME_WINDOW = 10L;

    /** entity UUID -> aliveTicks stamp of its most recent damage event. */
    private static final Map<UUID, Long> LAST_DAMAGE_TICK = new ConcurrentHashMap<>();

    /** entity UUID -> blocks fallen while airborne (reset to 0 on landing). */
    private static final Map<UUID, Double> FALL_DISTANCE = new ConcurrentHashMap<>();

    /** entity UUID -> previous sampled Y, for per-tick fall-distance deltas. */
    private static final Map<UUID, Double> LAST_Y = new ConcurrentHashMap<>();

    /** Blocks a living entity climbs (fall distance is meaningless on these). */
    private static final Set<String> CLIMBABLE = Set.of(
            "ladder", "vine", "scaffolding",
            "weeping_vines", "weeping_vines_plant",
            "twisting_vines", "twisting_vines_plant");

    private static boolean initialized = false;

    private EntityCombatTrackers() {
    }

    /** Wire the damage/tick/auto-clear listeners once; safe on every reload. */
    public static synchronized void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        GlobalEventHandler handler = MinecraftServer.getGlobalEventHandler();
        // i-frame timer: stamp the tick this entity last took damage.
        handler.addListener(EntityDamageEvent.class, event ->
                LAST_DAMAGE_TICK.put(event.getEntity().getUuid(),
                        event.getEntity().getAliveTicks()));
        // fall distance: sample every entity's Y once per tick.
        handler.addListener(EntityTickEvent.class, event -> onTick(event.getEntity()));
        // lifecycle: drop all three trackers when the entity goes away.
        handler.addListener(EntityDespawnEvent.class, event -> clearEntity(event.getEntity()));
        handler.addListener(PlayerDisconnectEvent.class, event -> clearEntity(event.getPlayer()));
    }

    /** One tick of fall-distance bookkeeping for a single entity. */
    private static void onTick(Entity entity) {
        UUID uuid = entity.getUuid();
        double y = entity.getPosition().y();
        Double prevY = LAST_Y.put(uuid, y);
        // Landed, or a flying player: no fall in progress.
        if (entity.isOnGround() || (entity instanceof Player player && player.isFlying())) {
            FALL_DISTANCE.put(uuid, 0.0);
            return;
        }
        // Airborne and descending: accumulate the drop (ignore upward motion).
        if (prevY != null && y < prevY) {
            FALL_DISTANCE.merge(uuid, prevY - y, Double::sum);
        }
    }

    /**
     * Ticks of vanilla-style invulnerability the entity still has, counting down
     * from {@link #IFRAME_WINDOW} since its last damage event; 0 if it has never
     * been damaged (or the window has elapsed). The runtime only reports this —
     * whether to actually veto an incoming hit is up to the {@code .sw} script.
     */
    public static int invulnerableTicks(Entity entity) {
        Long last = LAST_DAMAGE_TICK.get(entity.getUuid());
        if (last == null) {
            return 0;
        }
        long remaining = IFRAME_WINDOW - (entity.getAliveTicks() - last);
        if (remaining < 0) {
            return 0;
        }
        return (int) Math.min(IFRAME_WINDOW, remaining);
    }

    /**
     * Blocks the entity has fallen since it was last on the ground (0 while on
     * the ground or flying). Not tracked natively by Minestom — accumulated from
     * per-tick movement. Note: a teleport counts as movement, and climbing/water
     * do not auto-reset it (vanilla does); a script driving fall damage should
     * read this on the on_ground transition and reset via its own bookkeeping.
     */
    public static double fallDistance(Entity entity) {
        Double d = FALL_DISTANCE.get(entity.getUuid());
        return d == null ? 0.0 : d;
    }

    /**
     * Best-effort climbing read. Minestom exposes no climbing meta/flag, so this
     * is derived positionally: true when the block at the entity's feet is a
     * ladder/vine/scaffolding-family block. Not authoritative (it ignores the
     * per-mob "can climb" rule vanilla applies), but it is the same signal
     * vanilla uses and is enough for the crit "not climbing" condition.
     */
    public static boolean isClimbing(Entity entity) {
        Instance instance = entity.getInstance();
        if (instance == null) {
            return false;
        }
        Block block = instance.getBlock(entity.getPosition());
        return CLIMBABLE.contains(block.key().value());
    }

    /** Drop every tracker for one entity (despawn/disconnect auto-clear). */
    public static void clearEntity(Entity entity) {
        UUID uuid = entity.getUuid();
        LAST_DAMAGE_TICK.remove(uuid);
        FALL_DISTANCE.remove(uuid);
        LAST_Y.remove(uuid);
    }

    /** Wipe every tracker (hot-reload teardown / shutdown). */
    public static void clearAll() {
        LAST_DAMAGE_TICK.clear();
        FALL_DISTANCE.clear();
        LAST_Y.clear();
    }
}
