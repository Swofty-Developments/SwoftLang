package net.swofty.harness;

import java.io.File;
import java.nio.file.Files;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.serializer.legacy.LegacyComponentSerializer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.component.DataComponents;
import net.minestom.server.item.ItemStack;
import net.minestom.server.network.packet.client.play.ClientPlayerActionPacket;
import net.minestom.server.network.packet.server.SendablePacket;
import net.swofty.ScriptError;
import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.compiler.SwoftcCompiler;
import net.swofty.items.ItemRegistry;
import net.swofty.model.ItemDefModel;
import net.swofty.model.MobDefModel;
import net.swofty.packets.PacketListeners;
import net.swofty.packets.PacketSender;
import net.swofty.props.PropertyTables;

/**
 * Serverless phase-5 coverage: the item lore-assembly pipeline (rendered
 * legacy lines printed for inspection), tag round-trips, and packet NAME
 * RESOLUTION + canonical-constructor matching against the real pinned
 * packet classes - all without a Minestom server. The mob/nametag/interact
 * paths are smoked separately via MinecraftServer.init() in
 * Phase5Smoke.
 */
public final class Phase5Harness {
    private static final LegacyComponentSerializer LEGACY =
            LegacyComponentSerializer.legacySection();

    private Phase5Harness() {
    }

    static ParsedScript load(String path) throws Exception {
        File file = new File(path);
        String json = file.getName().endsWith(".json")
                ? Files.readString(file.toPath())
                : SwoftcCompiler.compile(file);
        return SwoftJsonLoader.load(json);
    }

    /**
     * --items-demo: register every item declaration and print the rendered
     * name + lore lines straight from the design-5A assembly pipeline
     * (fully serverless), then prove the stack identity + tag round-trip
     * (which needs the Minestom registries, so the server is initialized
     * lazily - never started).
     */
    public static int itemsDemo(String scriptPath) throws Exception {
        PropertyTables.ensureRegistered();
        ParsedScript parsed = load(scriptPath);
        if (parsed.items().isEmpty()) {
            System.err.println("[ITEMS] script declares no items");
            return 1;
        }
        ItemRegistry.clear();
        for (ItemDefModel item : parsed.items()) {
            ItemRegistry.register(item);
        }
        for (MobDefModel mob : parsed.mobs()) {
            net.swofty.mobs.MobRegistry.register(mob);
        }

        int failures = 0;
        // serverless: the lore assembly pipeline renders pure Components
        for (String id : ItemRegistry.ids()) {
            ItemDefModel def = ItemRegistry.get(id);
            System.out.println("[ITEM " + id + "] name: "
                    + LEGACY.serialize(net.swofty.items.ItemLoreBuilder.buildName(def)));
            for (Component line : net.swofty.items.ItemLoreBuilder.buildLore(def,
                    ItemRegistry.deepCopy(def.tags()))) {
                System.out.println("[ITEM " + id + "] lore: " + LEGACY.serialize(line));
            }
        }

        // stack materialization needs the registries (tool components read
        // block tags) - init the server process, do not start it
        if (net.minestom.server.MinecraftServer.process() == null) {
            net.minestom.server.MinecraftServer.init();
        }
        for (String id : ItemRegistry.ids()) {
            ItemStack stack = ItemRegistry.build(id, 1);
            System.out.println("[STACK " + id + "] material="
                    + stack.material().key().asString()
                    + " glint=" + Boolean.TRUE.equals(
                            stack.get(DataComponents.ENCHANTMENT_GLINT_OVERRIDE))
                    + " custom_id=" + ItemRegistry.customId(stack));
            if (!id.equals(ItemRegistry.customId(stack))) {
                System.err.println("[ITEMS] FAIL: identity tag round-trip broken for " + id);
                failures++;
            }
        }

        // tag round-trip with lore re-render on the first item declaring tags
        for (String id : ItemRegistry.ids()) {
            ItemDefModel def = ItemRegistry.get(id);
            if (def.tags().isEmpty()) {
                continue;
            }
            String key = firstScalarTag(def.tags());
            if (key == null) {
                continue;
            }
            Object bumped = bumpTag(def.tags().get(key));
            ItemStack stack = ItemRegistry.build(id, 1);
            ItemStack updated = ItemRegistry.withTags(stack, Map.of(key, bumped));
            Object readBack = ItemRegistry.readTags(updated).get(key);
            System.out.println("[TAGS " + id + "] " + key + ": "
                    + ItemRegistry.readTags(stack).get(key) + " -> " + readBack);
            List<Component> lore = updated.get(DataComponents.LORE);
            for (Component line : lore != null ? lore : List.<Component>of()) {
                System.out.println("[TAGS " + id + "] lore: " + LEGACY.serialize(line));
            }
            if (!String.valueOf(bumped).equals(String.valueOf(readBack))) {
                System.err.println("[ITEMS] FAIL: tag round-trip for " + id + "." + key
                        + " wrote " + bumped + " read " + readBack);
                failures++;
            }
            break;
        }
        System.out.println("[ITEMS] " + (failures == 0 ? "PASS" : failures + " failure(s)"));
        return failures == 0 ? 0 : 1;
    }

    /** The first top-level scalar tag key (skips nested compounds/lists). */
    private static String firstScalarTag(Map<String, Object> tags) {
        for (Map.Entry<String, Object> entry : tags.entrySet()) {
            Object value = entry.getValue();
            if (!(value instanceof Map) && !(value instanceof List)) {
                return entry.getKey();
            }
        }
        return null;
    }

    private static Object bumpTag(Object declared) {
        if (declared instanceof Boolean b) {
            return !b;
        }
        if (declared instanceof Integer i) {
            return i + 5;
        }
        if (declared instanceof Double d) {
            return d + 0.5;
        }
        return declared + "!";
    }

    /**
     * --packets-check: name resolution and canonical-record constructor
     * matching against the REAL pinned packet classes, without sending
     * anything. Includes nested records, enums, colors, lists, negative
     * shape errors, and the client-packet read path.
     */
    public static int packetsCheck() {
        int failures = 0;

        // 1. shape resolution (short names, .play + .common packages)
        for (String name : new String[]{"ParticlePacket", "SoundEffectPacket", "TeamsPacket",
                "BlockChangePacket", "ActionBarPacket", "PlayerInfoUpdatePacket",
                "DestroyEntitiesPacket", "KeepAlivePacket"}) {
            try {
                PacketSender.Shape shape = PacketSender.resolveServer(name);
                System.out.println("[SHAPE] " + shape.describe());
            } catch (ScriptError e) {
                System.err.println("[PACKETS] FAIL resolving " + name + ": " + e.getMessage());
                failures++;
            }
        }

        // 2. real construction: primitives + registry values
        try {
            Map<String, Object> fields = new LinkedHashMap<>();
            fields.put("particle", "flame");
            fields.put("overrideLimiter", false);
            fields.put("longDistance", false);
            fields.put("x", 100.5);
            fields.put("y", 65.0);
            fields.put("z", -20.0);
            fields.put("offsetX", 0.5);
            fields.put("offsetY", 0.5);
            fields.put("offsetZ", 0.5);
            fields.put("maxSpeed", 0.01);
            fields.put("particleCount", 40);
            SendablePacket packet = PacketSender.build("ParticlePacket", fields);
            System.out.println("[BUILD] ParticlePacket -> " + packet.getClass().getSimpleName());
        } catch (ScriptError e) {
            System.err.println("[PACKETS] FAIL building ParticlePacket: " + e.getMessage());
            failures++;
        }

        // 3. nested record variant + enum + color + component + string list
        try {
            // minestom 26.2 regrouped the flat CreateTeamAction fields into a
            // nested Settings record (teamColor was also renamed to color)
            Map<String, Object> settings = new LinkedHashMap<>();
            settings.put("displayName", "&6[MVP] ");
            settings.put("teamPrefix", "&6[MVP] ");
            settings.put("teamSuffix", "");
            settings.put("nameTagVisibility", "ALWAYS");
            settings.put("collisionRule", "ALWAYS");
            settings.put("color", "gold");
            settings.put("friendlyFlags", 1);
            Map<String, Object> action = new LinkedHashMap<>();
            action.put("type", "CreateTeamAction");
            action.put("settings", settings);
            action.put("entities", List.of("Swofty"));
            Map<String, Object> fields = new LinkedHashMap<>();
            fields.put("teamName", "ZZZZZSwofty");
            fields.put("action", action);
            SendablePacket packet = PacketSender.build("TeamsPacket", fields);
            System.out.println("[BUILD] TeamsPacket(CreateTeamAction) -> "
                    + packet.getClass().getSimpleName());
        } catch (ScriptError e) {
            System.err.println("[PACKETS] FAIL building TeamsPacket: " + e.getMessage());
            failures++;
        }

        // 4. Point coercion (canonical BlockChangePacket takes a state id)
        try {
            Map<String, Object> fields = new LinkedHashMap<>();
            fields.put("blockPosition", new Pos(1, 64, 2));
            fields.put("blockStateId", 1);
            PacketSender.build("BlockChangePacket", fields);
            System.out.println("[BUILD] BlockChangePacket ok");
        } catch (ScriptError e) {
            System.err.println("[PACKETS] FAIL building BlockChangePacket: " + e.getMessage());
            failures++;
        }

        // 5. negative: missing field must list the expected components
        try {
            PacketSender.build("ParticlePacket", Map.of("particle", "flame"));
            System.err.println("[PACKETS] FAIL: missing-field error not raised");
            failures++;
        } catch (ScriptError e) {
            boolean listsShape = e.getMessage().contains("particleCount")
                    && e.getMessage().contains("Expected:");
            System.out.println("[NEG missing-field] " + e.getMessage());
            if (!listsShape) {
                System.err.println("[PACKETS] FAIL: error does not list expected components");
                failures++;
            }
        }

        // 6. negative: unknown packet name
        try {
            PacketSender.resolveServer("ParticlesPacket");
            System.err.println("[PACKETS] FAIL: unknown-name error not raised");
            failures++;
        } catch (ScriptError e) {
            System.out.println("[NEG unknown-name] " + e.getMessage());
        }

        // 7. negative: bad enum constant lists valid values
        try {
            Map<String, Object> settings = new LinkedHashMap<>();
            settings.put("displayName", "");
            settings.put("teamPrefix", "");
            settings.put("teamSuffix", "");
            settings.put("nameTagVisibility", "SOMETIMES");
            settings.put("collisionRule", "ALWAYS");
            settings.put("color", "gold");
            settings.put("friendlyFlags", 1);
            Map<String, Object> action = new LinkedHashMap<>();
            action.put("type", "CreateTeamAction");
            action.put("settings", settings);
            action.put("entities", List.of("Swofty"));
            PacketSender.build("TeamsPacket", Map.of("teamName", "t", "action", action));
            System.err.println("[PACKETS] FAIL: bad-enum error not raised");
            failures++;
        } catch (ScriptError e) {
            System.out.println("[NEG bad-enum] " + e.getMessage());
            if (!e.getMessage().contains("ALWAYS")) {
                System.err.println("[PACKETS] FAIL: enum error does not list constants");
                failures++;
            }
        }

        // 8. client side: resolution + record-component read path
        try {
            Class<?> client = PacketSender.resolveClient("ClientPlayerActionPacket");
            System.out.println("[CLIENT] resolved " + client.getName());
            ClientPlayerActionPacket dig = new ClientPlayerActionPacket(
                    ClientPlayerActionPacket.Status.STARTED_DIGGING,
                    new Pos(1, 64, 2), net.minestom.server.instance.block.BlockFace.TOP, 7);
            Map<String, Object> view = PacketListeners.readFields(dig);
            System.out.println("[CLIENT] packet view: " + view);
            if (!"STARTED_DIGGING".equals(view.get("status"))
                    || !(view.get("blockPosition") instanceof Pos)
                    || !Integer.valueOf(7).equals(view.get("sequence"))) {
                System.err.println("[PACKETS] FAIL: client packet view mismatch: " + view);
                failures++;
            }
        } catch (Exception e) {
            System.err.println("[PACKETS] FAIL client path: " + e);
            failures++;
        }

        // 9. negative: network-thread packets are blacklisted from on packet
        try {
            Class<?> keepAlive = PacketSender.resolveClient("ClientKeepAlivePacket");
            int before = PacketListeners.handlerCount(keepAlive);
            PacketListeners.register(new net.swofty.model.PacketHandlerModel(
                    "ClientKeepAlivePacket", null, -1, -1));
            int after = PacketListeners.handlerCount(keepAlive);
            System.out.println("[NEG network-thread] handlerCount " + before + " -> " + after);
            if (after != before) {
                System.err.println("[PACKETS] FAIL: ClientKeepAlivePacket listener was"
                        + " registered despite the network-thread blacklist");
                failures++;
            }
        } catch (Exception e) {
            System.err.println("[PACKETS] FAIL blacklist path: " + e);
            failures++;
        }

        // 10. nametag wire form builds serverless
        try {
            var packet = net.swofty.nametags.NametagRuntime.buildPacket("Swofty",
                    new net.swofty.nametags.NametagRuntime.View("&c[ADMIN] ", "",
                            net.kyori.adventure.text.format.NamedTextColor.RED));
            System.out.println("[NAMETAG] " + packet.teamName() + " -> "
                    + packet.action().getClass().getSimpleName());
        } catch (Exception e) {
            System.err.println("[PACKETS] FAIL nametag packet: " + e);
            failures++;
        }

        System.out.println("[PACKETS] " + (failures == 0 ? "PASS" : failures + " failure(s)"));
        return failures == 0 ? 0 : 1;
    }
}
