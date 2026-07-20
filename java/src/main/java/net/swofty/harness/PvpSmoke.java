package net.swofty.harness;

import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.coordinate.Vec;
import net.minestom.server.entity.EntityType;
import net.minestom.server.entity.LivingEntity;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.attribute.Attribute;
import net.minestom.server.entity.damage.Damage;
import net.minestom.server.event.EventDispatcher;
import net.minestom.server.event.entity.EntityDamageEvent;
import net.minestom.server.event.entity.EntityTickEvent;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.block.Block;
import net.minestom.server.network.packet.server.SendablePacket;
import net.minestom.server.network.player.GameProfile;
import net.minestom.server.network.player.PlayerConnection;
import net.minestom.server.potion.PotionEffect;
import net.minestom.server.registry.RegistryKey;
import net.swofty.ASTExecutor;
import net.swofty.InstanceRegistry;
import net.swofty.entities.EntityCombatTrackers;
import net.swofty.entities.EntityStateStore;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.expressions.FunctionCallExpression;
import net.swofty.nativebridge.execution.expressions.NumberLiteral;
import net.swofty.nativebridge.execution.expressions.StringLiteral;
import net.swofty.nativebridge.execution.expressions.VariableReference;
import net.swofty.props.PathResolver;
import net.swofty.props.PropertyTables;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;

/**
 * --pvp-smoke: headless MinecraftServer.init() proofs for the W-pvp combat
 * primitives. Boots a real instance, spawns real living entities, and drives
 * every primitive through the script-facing builtin path
 * ({@link FunctionCallExpression} -&gt; {@code ExecutionContext.callFunction}
 * -&gt; {@code Builtins}) exactly as compiled {@code .sw} does, then asserts the
 * observable engine state. Covers: the per-entity state store (round-trip,
 * clear-on-remove), the unified {@code player.tags.*} freeform namespace
 * (set-on-join / read-a-tick-later round-trip + set-to-none delete),
 * attribute get/set + modifier add/remove,
 * {@code apply_effect}/{@code remove_effect}/{@code active_effects},
 * {@code apply_damage} through the pipeline, {@code apply_knockback} velocity,
 * the native {@code invulnerable_ticks} timer, and {@code fall_distance}
 * accumulation.
 */
public final class PvpSmoke {

    private PvpSmoke() {
    }

    private static int failures = 0;

    private static void check(String label, boolean ok, Object detail) {
        if (ok) {
            System.out.println("  ok   " + label);
        } else {
            failures++;
            System.out.println("  FAIL " + label + "  -> " + detail);
        }
    }

    private static boolean near(double a, double b) {
        return Math.abs(a - b) < 1.0e-6;
    }

    // ---- script-facing builtin call helpers -------------------------------
    private static ExecutionContext ctx;
    private static Map<String, Object> vars;

    private static Object bi(String name, Expression... args) {
        return ctx.callFunction(name, List.of(args));
    }

    private static Expression ref(String v) {
        return new VariableReference(v);
    }

    private static Expression num(double d) {
        return new NumberLiteral(d, false);
    }

    private static Expression str(String s) {
        return new StringLiteral(s);
    }

    public static int run() throws Exception {
        MinecraftServer.init();
        PropertyTables.ensureRegistered();
        // wire the W-pvp listeners the engine normally wires on reload
        EntityStateStore.init();
        EntityStateStore.clearAll();
        EntityCombatTrackers.init();
        EntityCombatTrackers.clearAll();

        InstanceContainer instance = MinecraftServer.getInstanceManager()
                .createInstanceContainer();
        instance.setGenerator(unit -> unit.modifier().fillHeight(0, 40, Block.STONE));
        instance.loadChunk(0, 0).join();
        InstanceRegistry.register("world", instance);

        vars = new HashMap<>();
        ctx = new ASTExecutor(
                MinecraftServer.getCommandManager().getConsoleSender(), vars).context();

        LivingEntity e = new LivingEntity(EntityType.ZOMBIE);
        e.setInstance(instance, new Pos(0, 42, 0)).join();
        vars.put("e", e);

        stateStoreChecks(e);
        playerTagsChecks(instance);
        attributeChecks(e);
        effectChecks(e);
        damageChecks(instance);
        knockbackChecks(e);
        invulnerableChecks(instance);
        fallDistanceChecks(instance);

        System.out.println(failures == 0
                ? "[pvp-smoke] all checks passed"
                : "[pvp-smoke] " + failures + " check(s) FAILED");
        return failures == 0 ? 0 : 1;
    }

    /**
     * State store: round-trip, remove-one-key, clear-on-remove. Exercised
     * through {@link EntityStateStore}'s public API directly — the scratch store
     * is no longer surfaced to scripts (freeform per-entity data now lives under
     * the unified {@code entity.tags.*} / {@code player.tags.*} namespace), but
     * the class remains as the ephemeral combat-bookkeeping primitive.
     */
    private static void stateStoreChecks(LivingEntity e) {
        System.out.println("[state store]");
        EntityStateStore.set(e, "hp", 5.0);
        Object got = EntityStateStore.get(e, "hp");
        check("get reflects set", got instanceof Double d && near(d, 5.0), got);
        check("has true", EntityStateStore.has(e, "hp"), null);

        // clear removes one key
        EntityStateStore.clear(e, "hp");
        check("clear removes key", !EntityStateStore.has(e, "hp"), null);
        check("get absent -> null", EntityStateStore.get(e, "hp") == null, null);

        // clears on entity removal
        EntityStateStore.set(e, "survive", 1.0);
        EntityStateStore.clearEntity(e);
        check("state cleared on remove", !EntityStateStore.has(e, "survive"), null);
    }

    /**
     * player.tags round-trip through the unified freeform namespace. Player is
     * an Entity, so {@code player.tags.<key>} resolves through the very same
     * {@code Entity.class} "tags" pass-through property (EntityTagsView backed by
     * the entity TagHandler) that mob/entity tags use. Drives the exact runtime
     * read/write path a compiled {@code set player.tags.k to v} statement takes
     * (PathResolver), proving values survive a later tick and that
     * {@code set ... to none} deletes.
     */
    private static void playerTagsChecks(InstanceContainer instance) {
        System.out.println("[player.tags]");
        Player p = new Player(new FakeConnection(), new GameProfile(UUID.randomUUID(), "Tagged"));
        p.setInstance(instance, new Pos(0, 42, 0)).join(); // "on join"
        Map<String, Object> pv = new HashMap<>();
        pv.put("p", p);

        // set player.tags.combat_tag to 5.0 and player.tags.weapon to "sword"
        PathResolver.assignVariablePath(pv, "p", List.of("tags", "combat_tag"), 5.0, 0, 0);
        PathResolver.assignVariablePath(pv, "p", List.of("tags", "weapon"), "sword", 0, 0);

        // ...survive a later tick, then read back through player.tags.<key>
        EventDispatcher.call(new EntityTickEvent(p));
        Object ct = PathResolver.getPath(p, List.of("tags", "combat_tag"), 0, 0);
        check("player.tags numeric round-trips across a tick",
                ct instanceof Double d && near(d, 5.0), ct);
        Object wp = PathResolver.getPath(p, List.of("tags", "weapon"), 0, 0);
        check("player.tags string round-trips", "sword".equals(wp), wp);

        // absent key reads as none, so it integrates with exists/otherwise
        Object absent = PathResolver.getPath(p, List.of("tags", "nope"), 0, 0);
        check("player.tags absent key -> none", NoneValue.isNone(absent), absent);

        // set player.tags.combat_tag to none deletes it
        PathResolver.assignVariablePath(pv, "p", List.of("tags", "combat_tag"),
                NoneValue.INSTANCE, 0, 0);
        Object afterDelete = PathResolver.getPath(p, List.of("tags", "combat_tag"), 0, 0);
        check("player.tags set-to-none deletes", NoneValue.isNone(afterDelete), afterDelete);
        // the sibling tag survives the delete
        Object stillWeapon = PathResolver.getPath(p, List.of("tags", "weapon"), 0, 0);
        check("player.tags sibling survives delete", "sword".equals(stillWeapon), stillWeapon);

        p.remove();
    }

    /** Attribute base get/set + modifier add (idempotent) / remove. */
    private static void attributeChecks(LivingEntity e) {
        System.out.println("[attributes]");
        bi("set_attribute", ref("e"), str("armor"), num(10.0));
        Object base = bi("attribute", ref("e"), str("armor"));
        check("set_attribute reflects", base instanceof Double d && near(d, 10.0), base);

        bi("add_attribute_modifier", ref("e"), str("armor"), str("testmod"), num(5.0),
                str("add_value"));
        double withMod = e.getAttribute(Attribute.ARMOR).getValue();
        check("modifier add_value applies (10+5)", near(withMod, 15.0), withMod);

        // re-adding under the same id must be idempotent, not stack to 20
        bi("add_attribute_modifier", ref("e"), str("armor"), str("testmod"), num(5.0),
                str("add_value"));
        double reAdd = e.getAttribute(Attribute.ARMOR).getValue();
        check("modifier re-add idempotent (still 15)", near(reAdd, 15.0), reAdd);

        bi("remove_attribute_modifier", ref("e"), str("armor"), str("testmod"));
        double removed = e.getAttribute(Attribute.ARMOR).getValue();
        check("modifier remove restores base (10)", near(removed, 10.0), removed);
    }

    /** apply_effect / active_effects / remove_effect. */
    private static void effectChecks(LivingEntity e) {
        System.out.println("[effects]");
        bi("apply_effect", ref("e"), str("speed"), num(100.0), num(1.0));
        // getEffectLevel returns the raw amplifier when present (1 here), -1 absent
        int level = e.getEffectLevel(PotionEffect.SPEED);
        check("apply_effect adds potion (amplifier round-trips as 1)", level == 1, level);

        Object active = bi("active_effects", ref("e"));
        check("active_effects lists speed",
                active instanceof List<?> l && l.contains("speed"), active);

        bi("remove_effect", ref("e"), str("speed"));
        check("remove_effect clears it (absent -> -1)",
                e.getEffectLevel(PotionEffect.SPEED) == -1,
                e.getEffectLevel(PotionEffect.SPEED));
    }

    /** apply_damage routes through the pipeline and lands on health. */
    private static void damageChecks(InstanceContainer instance) {
        System.out.println("[apply_damage]");
        // a raw LivingEntity defaults to max_health 1; raise it so the hit
        // registers as a real delta instead of clamping at 0
        LivingEntity t = new LivingEntity(EntityType.ZOMBIE);
        t.setInstance(instance, new Pos(4, 42, 0)).join();
        vars.put("t", t);
        bi("set_attribute", ref("t"), str("max_health"), num(20.0));
        t.setHealth(20.0f);
        float before = t.getHealth();
        // no source: bare typed damage through LivingEntity.damage(type, amount).
        // armor defaults to 0, so no native reduction: exact 6-point drop.
        bi("apply_damage", ref("t"), num(6.0), str("generic"));
        float after = t.getHealth();
        check("apply_damage lands (20 - 6 = 14)", near(after, 14.0),
                "before=" + before + " after=" + after);

        // with an attacker source: builds a full Damage so death-message /
        // knockback direction have an origin, still routes through damage().
        // fresh target to avoid the native single-hit invulnerability window.
        LivingEntity t2 = new LivingEntity(EntityType.ZOMBIE);
        t2.setInstance(instance, new Pos(5, 42, 0)).join();
        vars.put("t2", t2);
        bi("set_attribute", ref("t2"), str("max_health"), num(20.0));
        t2.setHealth(20.0f);
        LivingEntity src = new LivingEntity(EntityType.ZOMBIE);
        src.setInstance(instance, new Pos(6, 42, 0)).join();
        vars.put("src", src);
        bi("apply_damage", ref("t2"), num(3.0), str("player_attack"), ref("src"));
        float a2 = t2.getHealth();
        check("apply_damage with source lands (20 - 3 = 17)", near(a2, 17.0),
                "after=" + a2);
        check("damage source recorded as attacker",
                t2.getLastDamageSource() != null
                        && t2.getLastDamageSource().getAttacker() == src,
                t2.getLastDamageSource());
    }

    /** apply_knockback pushes velocity away from the source direction. */
    private static void knockbackChecks(LivingEntity e) {
        System.out.println("[apply_knockback]");
        e.setVelocity(Vec.ZERO);
        // direction (dx,dz) = (1,0): vanilla knockback pushes the target along
        // the normalized direction, so velocity gains a non-zero horizontal push
        bi("apply_knockback", ref("e"), num(1.0), num(1.0), num(0.0));
        Vec v = e.getVelocity();
        check("apply_knockback sets non-zero velocity",
                v.x() != 0.0 || v.z() != 0.0 || v.y() != 0.0, v);
        check("apply_knockback horizontal push on x axis", Math.abs(v.x()) > 0.0, v);
    }

    /** invulnerable_ticks: 0 fresh, full window right after a damage event. */
    private static void invulnerableChecks(InstanceContainer instance) {
        System.out.println("[invulnerable_ticks]");
        LivingEntity v = new LivingEntity(EntityType.ZOMBIE);
        v.setInstance(instance, new Pos(8, 42, 0)).join();
        vars.put("v", v);
        Object fresh = bi("invulnerable_ticks", ref("v"));
        check("invulnerable_ticks 0 before any damage",
                fresh instanceof Integer i && i == 0, fresh);

        // fire a real EntityDamageEvent so the tracker stamps aliveTicks
        RegistryKey<net.minestom.server.entity.damage.DamageType> key =
                RegistryKey.unsafeOf("minecraft:generic");
        Damage dmg = new Damage(key, null, null, v.getPosition(), 1.0f);
        EventDispatcher.call(new EntityDamageEvent(v, dmg, null));
        Object after = bi("invulnerable_ticks", ref("v"));
        // freshly spawned: aliveTicks ~0, window 10 -> full window remaining
        check("invulnerable_ticks reports window after damage",
                after instanceof Integer i && i == (int) EntityCombatTrackers.IFRAME_WINDOW,
                after);
    }

    /** fall_distance accumulates the downward drop across ticks. */
    private static void fallDistanceChecks(InstanceContainer instance) {
        System.out.println("[fall_distance]");
        LivingEntity f = new LivingEntity(EntityType.ZOMBIE);
        f.setInstance(instance, new Pos(0, 100, 0)).join();
        vars.put("f", f);
        // first tick: samples Y (100), no prior sample -> no accumulation yet
        EventDispatcher.call(new EntityTickEvent(f));
        Object t0 = bi("fall_distance", ref("f"));
        check("fall_distance 0 on first airborne tick",
                t0 instanceof Double d && near(d, 0.0), t0);

        // drop 3 blocks, tick again -> accumulate prevY - y = 3
        f.teleport(new Pos(0, 97, 0)).join();
        EventDispatcher.call(new EntityTickEvent(f));
        Object t1 = bi("fall_distance", ref("f"));
        check("fall_distance accumulates the 3-block drop",
                t1 instanceof Double d && near(d, 3.0), t1);
    }

    /** Minimal offline player connection so we can spawn a real Player headless. */
    private static final class FakeConnection extends PlayerConnection {
        @Override
        public void sendPacket(SendablePacket packet) {
        }

        @Override
        public SocketAddress getRemoteAddress() {
            return new InetSocketAddress(0);
        }
    }
}
