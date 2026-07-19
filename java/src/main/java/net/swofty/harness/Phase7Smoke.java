package net.swofty.harness;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.coordinate.Vec;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.EntityProjectile;
import net.minestom.server.entity.EntityType;
import net.minestom.server.entity.damage.Damage;
import net.minestom.server.event.EventDispatcher;
import net.minestom.server.event.entity.EntityAttackEvent;
import net.minestom.server.event.entity.EntityShootEvent;
import net.minestom.server.event.entity.projectile.ProjectileCollideWithEntityEvent;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.block.Block;
import net.swofty.ASTExecutor;
import net.swofty.InstanceRegistry;
import net.swofty.ScriptError;
import net.swofty.displays.SwoftDisplay;
import net.swofty.entities.ProjectileRuntime;
import net.swofty.entities.ScriptEntityRegistry;
import net.swofty.event.EventCatalog;
import net.swofty.event.EventRegistrar;
import net.swofty.event.EventType;
import net.swofty.event.events.GenericSwoftEvent;
import net.swofty.mobs.MobRegistry;
import net.swofty.mobs.SwoftMob;
import net.swofty.model.MobDefModel;
import net.swofty.nativebridge.execution.commands.CancelEventStatement;
import net.swofty.nativebridge.execution.commands.SetPropertyStatement;
import net.swofty.nativebridge.execution.commands.entities.DismountEntityStatement;
import net.swofty.nativebridge.execution.commands.entities.LaunchProjectileStatement;
import net.swofty.nativebridge.execution.commands.entities.MountEntityStatement;
import net.swofty.nativebridge.execution.commands.entities.RemoveEntityStatement;
import net.swofty.nativebridge.execution.commands.entities.SpawnEntityStatement;
import net.swofty.nativebridge.execution.commands.displays.MountDisplayStatement;
import net.swofty.nativebridge.execution.expressions.PropertyAccessExpression;
import net.swofty.nativebridge.execution.expressions.StringLiteral;
import net.swofty.nativebridge.execution.expressions.VariableReference;
import net.swofty.nativebridge.representation.Event;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.props.NoneValue;
import net.swofty.props.PathResolver;
import net.swofty.props.PropertyTables;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * --phase7-smoke: headless MinecraftServer.init() proofs for the phase-7
 * entity system and generic catalog events. Spawns real entities into a
 * real instance and drives everything through the script-facing
 * machinery (statements, PathResolver rows, EventRegistrar + the global
 * event handler) rather than raw Minestom calls, then asserts the
 * observable engine state.
 */
public final class Phase7Smoke {

    private Phase7Smoke() {
    }

    public static int run() throws Exception {
        MinecraftServer ignored = MinecraftServer.init();
        PropertyTables.ensureRegistered();

        InstanceContainer instance = MinecraftServer.getInstanceManager()
                .createInstanceContainer();
        instance.setGenerator(unit -> unit.modifier().fillHeight(0, 40, Block.STONE));
        instance.loadChunk(0, 0).join();
        InstanceRegistry.register("world", instance);

        Map<String, Object> vars = new HashMap<>();
        ExecutionContext context = new ASTExecutor(
                MinecraftServer.getCommandManager().getConsoleSender(), vars).context();

        int failures = 0;
        failures += entityChecks(context, vars, instance);
        failures += mountChecks(context, vars, instance);
        // projectile checks run BEFORE genericEventChecks: the generic-event
        // section registers a script handler that cancels EntityShoot, and
        // launches now genuinely dispatch that event
        failures += projectileChecks(context, vars);
        failures += removalChecks(context, vars);
        failures += damageBridgeChecks(instance);
        failures += sweepChecks(vars);
        failures += genericEventChecks();

        System.out.println("[PHASE7] " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures == 0 ? 0 : 1;
    }

    // ------------------------------------------------------------------
    // spawn + TEntity property rows
    // ------------------------------------------------------------------

    private static int entityChecks(ExecutionContext context, Map<String, Object> vars,
                                    InstanceContainer instance) throws Exception {
        int failures = 0;
        vars.put("spawn_pos", new Pos(0.5, 42, 0.5));

        new SpawnEntityStatement(new StringLiteral("ARMOR_STAND"),
                new VariableReference("spawn_pos"), "e").execute(context);
        Object bound = vars.get("e");
        if (!(bound instanceof Entity entity)
                || !EntityType.ARMOR_STAND.equals(entity.getEntityType())) {
            System.err.println("[PHASE7] FAIL spawn entity did not bind an armor stand: "
                    + bound);
            return 1;
        }
        failures += awaitInstance(entity, "spawned entity");
        failures += expect("type row", "minecraft:armor_stand",
                PathResolver.getProperty(entity, "type", 0, 0));
        failures += expect("is a Entity", true, Values.isType(entity, "Entity"));
        // uuid row is the STRING form, matching the checker's TString row
        // and the uuid_of() builtin
        failures += expect("uuid row stringified", entity.getUuid().toString(),
                PathResolver.getProperty(entity, "uuid", 0, 0));

        // velocity as a Vec value: whole-vector write, component read,
        // nested component write through the wither hop
        PathResolver.assignVariablePath(vars, "e", List.of("velocity"),
                new Vec(1, 2, 3), 0, 0);
        Object velocity = PathResolver.getProperty(entity, "velocity", 0, 0);
        failures += expect("velocity read back", new Vec(1, 2, 3), velocity);
        // 'is a Vec' must hold at runtime for the type name the checker uses
        failures += expect("velocity is a Vec", true, Values.isType(velocity, "Vec"));
        failures += expect("velocity.x row", 1.0,
                PathResolver.getProperty(velocity, "x", 0, 0));
        PathResolver.assignVariablePath(vars, "e", List.of("velocity", "y"), 7, 0, 0);
        failures += expect("velocity.y nested write", 7.0,
                PathResolver.getProperty(
                        PathResolver.getProperty(entity, "velocity", 0, 0), "y", 0, 0));

        // metadata rows: write through the registry, read back through it
        PathResolver.assignVariablePath(vars, "e", List.of("glowing"), true, 0, 0);
        PathResolver.assignVariablePath(vars, "e", List.of("custom_name"), "Seven", 0, 0);
        PathResolver.assignVariablePath(vars, "e", List.of("name_visible"), true, 0, 0);
        PathResolver.assignVariablePath(vars, "e", List.of("gravity"), false, 0, 0);
        PathResolver.assignVariablePath(vars, "e", List.of("invisible"), true, 0, 0);
        PathResolver.assignVariablePath(vars, "e", List.of("silent"), true, 0, 0);
        PathResolver.assignVariablePath(vars, "e", List.of("on_fire"), true, 0, 0);
        failures += expect("glowing", true, PathResolver.getProperty(entity, "glowing", 0, 0));
        failures += expect("custom_name", "Seven",
                PathResolver.getProperty(entity, "custom_name", 0, 0));
        failures += expect("name_visible", true,
                PathResolver.getProperty(entity, "name_visible", 0, 0));
        failures += expect("gravity off", false,
                PathResolver.getProperty(entity, "gravity", 0, 0));
        failures += expect("no-gravity raw flag", true, entity.hasNoGravity());
        failures += expect("invisible", true,
                PathResolver.getProperty(entity, "invisible", 0, 0));
        failures += expect("silent", true, PathResolver.getProperty(entity, "silent", 0, 0));
        failures += expect("on_fire", true, PathResolver.getProperty(entity, "on_fire", 0, 0));
        failures += expect("alive", true, PathResolver.getProperty(entity, "alive", 0, 0));
        failures += expect("removed", false,
                PathResolver.getProperty(entity, "removed", 0, 0));
        failures += expect("vehicle none", NoneValue.INSTANCE,
                PathResolver.getProperty(entity, "vehicle", 0, 0));
        failures += expect("passengers empty", List.of(),
                PathResolver.getProperty(entity, "passengers", 0, 0));

        // Mob remains a subtype path: SwoftMob IS an EntityCreature, so
        // the Entity rows resolve on it through the superclass walk
        SwoftMob mob = new SwoftMob(new MobDefModel("smoke_pig", "PIG", null,
                20, 2, 0.25, "none", List.of(), null, null, null, null));
        failures += expect("mob is a Entity", true, Values.isType(mob, "Entity"));
        failures += expect("mob is a Mob", true, Values.isType(mob, "Mob"));
        PathResolver.assignObjectPath(mob, List.of("glowing"), true, 0, 0);
        failures += expect("Entity row on mob (glowing)", true,
                PathResolver.getProperty(mob, "glowing", 0, 0));
        Object mobVelocity = PathResolver.getProperty(mob, "velocity", 0, 0);
        failures += expect("Entity row on mob (velocity)", true, mobVelocity instanceof Vec);
        failures += expect("entity type row on mob", "minecraft:pig",
                PathResolver.getProperty(mob, "type", 0, 0));
        failures += expect("mob-specific name row", "smoke_pig",
                PathResolver.getProperty(mob, "name", 0, 0));

        System.out.println("[PHASE7] entity rows: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // mount / dismount (entities + displays through one statement)
    // ------------------------------------------------------------------

    private static int mountChecks(ExecutionContext context, Map<String, Object> vars,
                                   InstanceContainer instance) throws Exception {
        int failures = 0;
        Entity rider = (Entity) vars.get("e");

        new SpawnEntityStatement(new StringLiteral("minecraft:pig"),
                new VariableReference("spawn_pos"), "b").execute(context);
        Entity vehicle = (Entity) vars.get("b");
        failures += awaitInstance(vehicle, "mount vehicle");

        new MountEntityStatement(new VariableReference("e"),
                new VariableReference("b")).execute(context);
        failures += expect("vehicle has passenger", true,
                vehicle.getPassengers().contains(rider));
        failures += expect("vehicle row", vehicle,
                PathResolver.getProperty(rider, "vehicle", 0, 0));
        Object passengers = PathResolver.getProperty(vehicle, "passengers", 0, 0);
        failures += expect("passengers row", true,
                passengers instanceof List<?> list && list.contains(rider));

        new DismountEntityStatement(new VariableReference("e")).execute(context);
        failures += expect("dismounted", true, vehicle.getPassengers().isEmpty());
        failures += expect("vehicle row cleared", NoneValue.INSTANCE,
                PathResolver.getProperty(rider, "vehicle", 0, 0));

        // displays ride through the same mount statement
        SwoftDisplay display = new SwoftDisplay(SwoftDisplay.Kind.TEXT);
        display.setText("phase7");
        display.spawn(instance, new Pos(0.5, 43, 0.5));
        failures += awaitInstance(display.entity(), "display entity");
        vars.put("d", display);
        new MountEntityStatement(new VariableReference("d"),
                new VariableReference("b")).execute(context);
        failures += expect("display mounted on entity", vehicle,
                display.entity().getVehicle());
        new DismountEntityStatement(new VariableReference("d")).execute(context);
        failures += expect("display dismounted", true, vehicle.getPassengers().isEmpty());

        // mount cycles land as clean ScriptErrors, never a tick-thread
        // StackOverflowError (or Minestom's raw IllegalStateException)
        failures += expectScriptError("display self-mount", () ->
                new MountDisplayStatement(new VariableReference("d"),
                        new VariableReference("d")).execute(context));
        display.destroy();

        new MountEntityStatement(new VariableReference("e"),
                new VariableReference("b")).execute(context);
        failures += expectScriptError("direct 2-cycle mount", () ->
                new MountEntityStatement(new VariableReference("b"),
                        new VariableReference("e")).execute(context));
        new SpawnEntityStatement(new StringLiteral("minecraft:cow"),
                new VariableReference("spawn_pos"), "c").execute(context);
        Entity third = (Entity) vars.get("c");
        failures += awaitInstance(third, "cycle third entity");
        new MountEntityStatement(new VariableReference("b"),
                new VariableReference("c")).execute(context);
        failures += expectScriptError("indirect 3-cycle mount", () ->
                new MountEntityStatement(new VariableReference("c"),
                        new VariableReference("e")).execute(context));
        failures += expect("cycle attempts left the chain intact", true,
                rider.getVehicle() == vehicle && vehicle.getVehicle() == third
                        && third.getVehicle() == null);
        new DismountEntityStatement(new VariableReference("e")).execute(context);
        new DismountEntityStatement(new VariableReference("b")).execute(context);

        System.out.println("[PHASE7] mount/dismount: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // generic catalog events through the global event handler
    // ------------------------------------------------------------------

    private static int genericEventChecks() {
        int failures = 0;

        // curated wrappers keep precedence: PlayerChat is both curated
        // and in the generated catalog, and the curated identifier wins
        failures += expect("curated PlayerChat stays curated", true,
                EventType.fromIdentifier("PlayerChat") != null);
        failures += expect("catalog also knows PlayerChat", true,
                EventCatalog.resolve("PlayerChat").isPresent());

        // catalog resolution: short name, short+Event, fully qualified
        failures += expect("short name resolves", true,
                EventCatalog.resolve("EntityShoot").isPresent());
        failures += expect("suffixed name resolves", true,
                EventCatalog.resolve("EntityShootEvent").isPresent());
        failures += expect("class name resolves", true,
                EventCatalog.resolve(
                        "net.minestom.server.event.entity.EntityShootEvent").isPresent());
        // minestom 26.2's regenerated catalog carries more entity events (was 87)
        failures += expect("catalog size", 101, EventCatalog.entries().size());

        // the ENGINE PlayerUseItemEvent stays reachable: the curated
        // 'PlayerUseItem' identifier wraps the custom-items event
        // (PlayerUseCustomItemEvent), so the class spelling must miss the
        // curated router and resolve generically to the engine class
        failures += expect("PlayerUseItemEvent is not curated", true,
                EventType.fromIdentifier("PlayerUseItemEvent") == null);
        failures += expect("PlayerUseItemEvent resolves to the engine event",
                "net.minestom.server.event.player.PlayerUseItemEvent",
                EventCatalog.resolve("PlayerUseItemEvent")
                        .map(EventCatalog.Entry::className).orElse("<unresolved>"));
        // registers generically (also warms the reflective property table)
        new EventRegistrar().registerEvent(new Event("PlayerUseItemEvent"));

        // register ONE generic handler and fire the event synthetically
        // through the global event handler; the handler reads a catalog
        // property, writes another through the coercion table, cancels
        Event scriptEvent = new Event("EntityShoot");
        ExecuteBlock block = new ExecuteBlock();
        SetPropertyStatement copyPowerToSpread = new SetPropertyStatement(
                new VariableReference("event"), "spread",
                new PropertyAccessExpression(new VariableReference("event"), "power"));
        block.addStatement(copyPowerToSpread);
        block.addStatement(new CancelEventStatement());
        scriptEvent.setExecuteBlock(block);
        new EventRegistrar().registerEvent(scriptEvent);

        Entity shooter = new Entity(EntityType.SKELETON);
        Entity arrow = new Entity(EntityType.ARROW);
        EntityShootEvent raw = new EntityShootEvent(shooter, arrow,
                new Pos(1, 2, 3), 2.5, 0.0);
        EventDispatcher.call(raw);

        failures += expect("handler cancelled the event", true, raw.isCancelled());
        failures += expect("handler read power + wrote spread", 2.5, raw.getSpread());

        // wrapper property access from outside a handler
        GenericSwoftEvent wrapper = new GenericSwoftEvent(raw, scriptEvent);
        failures += expect("generic read (power)", 2.5,
                PathResolver.getProperty(wrapper, "power", 0, 0));
        failures += expect("generic read (cancelled)", true,
                PathResolver.getProperty(wrapper, "cancelled", 0, 0));
        Object to = PathResolver.getProperty(wrapper, "to", 0, 0);
        failures += expect("generic read (to as Location)", new Pos(1, 2, 3), to);
        PathResolver.assignObjectPath(wrapper, List.of("power"), 9, 0, 0);
        failures += expect("generic coerced write (power)", 9.0, raw.getPower());

        // non-cancellable catalog event: reads work, cancel write errors
        EntityAttackEvent attack = new EntityAttackEvent(shooter, arrow);
        GenericSwoftEvent attackWrapper = new GenericSwoftEvent(attack,
                new Event("EntityAttack"));
        failures += expect("generic read (target)", arrow,
                PathResolver.getProperty(attackWrapper, "target", 0, 0));
        try {
            attackWrapper.setDynamicProperty("cancelled", true, 0, 0);
            System.err.println("[PHASE7] FAIL cancelling a non-cancellable event "
                    + "must error");
            failures++;
        } catch (ScriptError expected) {
            // ok
        }
        try {
            PathResolver.getProperty(attackWrapper, "no_such_prop", 0, 0);
            System.err.println("[PHASE7] FAIL unknown generic property must error");
            failures++;
        } catch (ScriptError expected) {
            // ok
        }

        // unknown event names come back with suggestions, not a crash
        new EventRegistrar().registerEvent(new Event("EntityShoott"));
        failures += expect("suggestions for near-miss", true,
                EventCatalog.suggest("EntityShoott", 3).contains("EntityShoot"));

        System.out.println("[PHASE7] generic events: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // launch projectile + all_entities
    // ------------------------------------------------------------------

    private static int projectileChecks(ExecutionContext context, Map<String, Object> vars)
            throws Exception {
        int failures = 0;
        Entity shooter = (Entity) vars.get("e");

        // launching must dispatch the REAL EntityShootEvent (no synthetic
        // fire): record deliveries straight off the global event handler
        List<EntityShootEvent> shots = new ArrayList<>();
        MinecraftServer.getGlobalEventHandler()
                .addListener(EntityShootEvent.class, shots::add);

        new LaunchProjectileStatement(new StringLiteral("SNOWBALL"),
                new VariableReference("e"), null, null, "p").execute(context);
        Object bound = vars.get("p");
        if (!(bound instanceof EntityProjectile projectile)) {
            System.err.println("[PHASE7] FAIL launch projectile did not bind an "
                    + "EntityProjectile: " + bound);
            return 1;
        }
        failures += awaitInstance(projectile, "projectile");
        failures += expect("projectile shooter", shooter, projectile.getShooter());
        failures += expect("projectile type", "minecraft:snowball",
                PathResolver.getProperty(projectile, "type", 0, 0));
        failures += expect("EntityShootEvent fired on launch", 1, shots.size());
        if (!shots.isEmpty()) {
            EntityShootEvent shot = shots.get(0);
            failures += expect("shoot event shooter", shooter, shot.getEntity());
            failures += expect("shoot event projectile", projectile,
                    shot.getProjectile());
            failures += expect("shoot event power (blocks/tick)", 1.5,
                    shot.getPower());
        }
        // scripts can read projectile ownership; non-projectiles read none
        failures += expect("shooter row on projectile", shooter,
                PathResolver.getProperty(projectile, "shooter", 0, 0));
        failures += expect("shooter row none on plain entity", NoneValue.INSTANCE,
                PathResolver.getProperty(shooter, "shooter", 0, 0));

        // default velocity: look direction (yaw 0 -> +z) * 1.5 b/t * 20
        Vec velocity = projectile.getVelocity();
        if (Math.abs(velocity.z() - 30.0) > 0.01 || Math.abs(velocity.x()) > 0.01) {
            System.err.println("[PHASE7] FAIL default projectile velocity should be "
                    + "~(0, 0, 30), got " + velocity);
            failures++;
        }

        // spawn height: shooter position + eye height
        double expectedY = shooter.getPosition().y() + shooter.getEyeHeight();
        if (Math.abs(projectile.getPosition().y() - expectedY) > 0.01) {
            System.err.println("[PHASE7] FAIL projectile should spawn at eye height "
                    + expectedY + ", got " + projectile.getPosition().y());
            failures++;
        }

        // explicit velocity overrides the look direction
        vars.put("explicit_velocity", new Vec(0, 5, 0));
        new LaunchProjectileStatement(new StringLiteral("SNOWBALL"),
                new VariableReference("e"),
                new VariableReference("explicit_velocity"), null, "p2").execute(context);
        EntityProjectile explicit = (EntityProjectile) vars.get("p2");
        failures += expect("explicit projectile velocity", new Vec(0, 5, 0),
                explicit.getVelocity());
        failures += expect("second launch fired EntityShootEvent too", 2,
                shots.size());

        // all_entities sees everything; the type filter narrows
        Object all = context.callFunction("all_entities", List.of());
        failures += expect("all_entities is a list", true, all instanceof List<?>);
        List<?> allList = (List<?>) all;
        failures += expect("all_entities contains shooter", true,
                allList.contains(shooter));
        failures += expect("all_entities contains projectile", true,
                allList.contains(projectile));
        Object stands = context.callFunction("all_entities",
                List.of(new StringLiteral("ARMOR_STAND")));
        failures += expect("all_entities(type) filters", true,
                stands instanceof List<?> list && list.size() == 1
                        && list.contains(shooter));

        explicit.remove();
        System.out.println("[PHASE7] projectiles: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // removal
    // ------------------------------------------------------------------

    private static int removalChecks(ExecutionContext context, Map<String, Object> vars) {
        int failures = 0;
        Entity projectile = (Entity) vars.get("p");
        new RemoveEntityStatement(new VariableReference("p")).execute(context);
        failures += expect("removed row after remove entity", true,
                PathResolver.getProperty(projectile, "removed", 0, 0));
        failures += expect("alive row after remove entity", false,
                PathResolver.getProperty(projectile, "alive", 0, 0));
        System.out.println("[PHASE7] removal: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // projectile hit -> damage with shooter attribution
    // ------------------------------------------------------------------

    private static int damageBridgeChecks(InstanceContainer instance) throws Exception {
        int failures = 0;
        ProjectileRuntime.init();

        SwoftMob target = new SwoftMob(new MobDefModel("bridge_cow", "COW", null,
                20, 2, 0.25, "none", List.of(), null, null, null, null));
        target.setInstance(instance, new Pos(2.5, 42, 2.5));
        failures += awaitInstance(target, "damage bridge target");

        Entity archer = new Entity(EntityType.SKELETON);
        EntityProjectile arrow = new EntityProjectile(archer, EntityType.ARROW);
        float before = target.getHealth();
        EventDispatcher.call(new ProjectileCollideWithEntityEvent(arrow,
                target.getPosition(), target));

        failures += expect("collision applied damage", true,
                target.getHealth() < before);
        Damage last = target.getLastDamageSource();
        failures += expect("damage attributed to the shooter", true,
                last != null && last.getAttacker() == archer);
        failures += expect("projectile spent on the hit", true, arrow.isRemoved());

        // finding-8 companion: a re-register cycle must REMOVE live mobs,
        // not orphan them in the world while all_mobs() forgets them
        failures += expect("live mob tracked before clear", true,
                MobRegistry.all(null).contains(target));
        MobRegistry.clear();
        failures += expect("clear() removed the live mob", true, target.isRemoved());
        failures += expect("all_mobs empty after clear", 0, MobRegistry.all(null).size());

        System.out.println("[PHASE7] damage bridge: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // script-entity registry sweep (reload/shutdown cleanup)
    // ------------------------------------------------------------------

    private static int sweepChecks(Map<String, Object> vars) {
        int failures = 0;
        Entity spawned = (Entity) vars.get("e");
        Entity vehicle = (Entity) vars.get("b");
        Entity third = (Entity) vars.get("c");
        // e, b, c live; p was untracked by 'remove entity'; p2 was removed
        // directly and pruned
        failures += expect("script entities tracked", 3, ScriptEntityRegistry.count());
        ScriptEntityRegistry.removeAll();
        failures += expect("sweep removed the spawned entities", true,
                spawned.isRemoved() && vehicle.isRemoved() && third.isRemoved());
        failures += expect("registry empty after sweep", 0,
                ScriptEntityRegistry.count());
        System.out.println("[PHASE7] entity sweep: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    private static int awaitInstance(Entity entity, String what)
            throws InterruptedException {
        long deadline = System.currentTimeMillis() + 10_000;
        while (System.currentTimeMillis() < deadline) {
            if (entity.getInstance() != null) {
                return 0;
            }
            Thread.sleep(20);
        }
        System.err.println("[PHASE7] FAIL " + what + " never entered its instance");
        return 1;
    }

    private static int expect(String what, Object expected, Object actual) {
        if (expected.equals(actual)) {
            return 0;
        }
        System.err.println("[PHASE7] FAIL " + what + ": expected " + expected
                + ", got " + actual);
        return 1;
    }

    private static int expectScriptError(String what, Runnable action) {
        try {
            action.run();
        } catch (ScriptError expected) {
            return 0;
        } catch (Throwable wrong) {
            System.err.println("[PHASE7] FAIL " + what
                    + " must throw ScriptError, threw " + wrong.getClass().getName()
                    + ": " + wrong.getMessage());
            return 1;
        }
        System.err.println("[PHASE7] FAIL " + what + " must throw ScriptError");
        return 1;
    }
}
