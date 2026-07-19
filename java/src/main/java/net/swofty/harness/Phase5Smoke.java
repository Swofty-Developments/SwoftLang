package net.swofty.harness;

import java.util.concurrent.TimeUnit;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.attribute.Attribute;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.block.Block;
import net.swofty.InstanceRegistry;
import net.swofty.TextFormat;
import net.swofty.compiler.ParsedScript;
import net.swofty.items.ItemInteractRuntime;
import net.swofty.items.ItemAttributeTask;
import net.swofty.items.ItemRegistry;
import net.swofty.mobs.MobRegistry;
import net.swofty.mobs.MobRuntime;
import net.swofty.mobs.SwoftMob;
import net.swofty.model.ItemDefModel;
import net.swofty.model.MobDefModel;
import net.swofty.model.PacketHandlerModel;
import net.swofty.nametags.NametagRuntime;
import net.swofty.packets.PacketListeners;
import net.swofty.props.PropertyTables;

/**
 * --phase5-smoke: headless MinecraftServer.init() coverage of the paths
 * that need a server process: mob construction (attributes, AI groups,
 * live nametag render), instance spawn/despawn, the interact/attribute/
 * nametag/packet listener registrations, and the ability cooldown gate.
 * Exits the JVM explicitly because init() starts non-daemon threads.
 */
public final class Phase5Smoke {
    private Phase5Smoke() {
    }

    public static int run(String scriptPath) throws Exception {
        MinecraftServer ignored = MinecraftServer.init();
        PropertyTables.ensureRegistered();

        ParsedScript parsed = Phase5Harness.load(scriptPath);
        ItemRegistry.clear();
        for (ItemDefModel item : parsed.items()) {
            ItemRegistry.register(item);
        }
        MobRegistry.clear();
        for (MobDefModel mob : parsed.mobs()) {
            MobRegistry.register(mob);
        }
        int failures = 0;

        // listener/task registrations (interact, equipment scan, attack,
        // nametags, packet dispatch) must all wire without error
        ItemInteractRuntime.init();
        ItemAttributeTask.init();
        MobRuntime.init();
        NametagRuntime.init();
        PacketListeners.clear();
        for (PacketHandlerModel handler : parsed.packetHandlers()) {
            PacketListeners.register(handler);
        }
        System.out.println("[SMOKE] runtimes initialized");

        // mob construction path: attributes, AI, live name render
        if (MobRegistry.ids().isEmpty()) {
            System.err.println("[SMOKE] FAIL: no mobs declared");
            return 1;
        }
        String mobId = MobRegistry.ids().get(0);
        SwoftMob probe = new SwoftMob(MobRegistry.require(mobId));
        double maxHealth = probe.getAttributeValue(Attribute.MAX_HEALTH);
        double speed = probe.getAttributeValue(Attribute.MOVEMENT_SPEED);
        int aiGroups = probe.getAIGroups().size();
        String plainName = probe.getCustomName() != null
                ? TextFormat.plain(probe.getCustomName()) : "(none)";
        System.out.println("[SMOKE] mob " + mobId + ": type="
                + probe.getEntityType().key().asString() + " max_health=" + maxHealth
                + " speed=" + speed + " ai_groups=" + aiGroups
                + " name='" + plainName + "' name_visible=" + probe.isCustomNameVisible());
        MobDefModel def = MobRegistry.require(mobId);
        if (maxHealth != def.health() || aiGroups < 1 || !probe.isCustomNameVisible()) {
            System.err.println("[SMOKE] FAIL: mob init mismatch");
            failures++;
        }

        // spawn into a real instance, then despawn
        try {
            InstanceContainer instance = MinecraftServer.getInstanceManager()
                    .createInstanceContainer();
            instance.setGenerator(unit ->
                    unit.modifier().fillHeight(0, 40, Block.STONE));
            InstanceRegistry.register("world", instance);
            SwoftMob live = new SwoftMob(def);
            live.setInstance(instance, new Pos(0, 42, 0)).get(10, TimeUnit.SECONDS);
            int alive = MobRegistry.all(mobId).size();
            System.out.println("[SMOKE] spawned into instance, live=" + alive);
            if (alive != 1) {
                System.err.println("[SMOKE] FAIL: live mob list expected 1, got " + alive);
                failures++;
            }
            live.remove();
            int after = MobRegistry.all(mobId).size();
            System.out.println("[SMOKE] despawned, live=" + after);
            if (after != 0) {
                System.err.println("[SMOKE] FAIL: mob not untracked on despawn");
                failures++;
            }
        } catch (Exception e) {
            System.err.println("[SMOKE] FAIL: instance spawn path: " + e);
            failures++;
        }

        // cooldowns are userland now (abilities.sw with_cooldown), proven
        // serverless in Phase9Harness rather than baked into the runtime

        System.out.println("[SMOKE] " + (failures == 0 ? "PASS" : failures + " failure(s)"));
        return failures == 0 ? 0 : 1;
    }
}
