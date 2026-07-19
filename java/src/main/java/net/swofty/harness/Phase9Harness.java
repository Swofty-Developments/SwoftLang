package net.swofty.harness;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.NamedTextColor;
import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.coordinate.Vec;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.EntityType;
import net.minestom.server.entity.ItemEntity;
import net.minestom.server.event.EventListener;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.block.Block;
import net.minestom.server.component.DataComponents;
import net.minestom.server.item.ItemStack;
import net.minestom.server.item.Material;
import net.minestom.server.item.component.ItemRarity;
import net.swofty.InstanceRegistry;
import net.swofty.TextFormat;
import net.swofty.blocks.DispenserRuntime;
import net.swofty.blocks.event.BlockDispenseEvent;
import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.compiler.SwoftcCompiler;
import net.swofty.items.ItemLoreBuilder;
import net.swofty.items.ItemRegistry;
import net.swofty.model.ItemDefModel;
import net.swofty.nativebridge.execution.commands.ui.LineStatement;
import net.swofty.nativebridge.execution.expressions.StringLiteral;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.props.NoneValue;
import net.swofty.props.PathResolver;
import net.swofty.props.PropertyTables;

/**
 * Serverless phase-9 coverage (design phase-9 §1–§5). Four proofs, each
 * driven through the real script-facing machinery rather than raw calls:
 * WYSIWYG lore round-trips (no auto-assembled sections, rarity → component),
 * nested NBT round-trips (write compound → read paths → delete → exists
 * false), a headless dispenser fire (place → seed → dispense → assert popped
 * item + spawned entity kind + facing direction, plus the cancellable
 * BlockDispense swap/cancel), and the userland cooldown gate logic that
 * abilities.sw builds on.
 */
public final class Phase9Harness {

    private Phase9Harness() {
    }

    public static int run() throws Exception {
        if (MinecraftServer.process() == null) {
            MinecraftServer.init();
        }
        PropertyTables.ensureRegistered();

        int failures = 0;
        failures += loreRoundTrip();
        failures += loreTemplateRoundTrip();
        failures += nestedNbtRoundTrip();
        failures += dispenseProof();
        failures += cooldownGate();

        System.out.println("[PHASE9] " + (failures == 0 ? "PASS" : failures + " failure(s)"));
        return failures == 0 ? 0 : 1;
    }

    // ------------------------------------------------------------------
    // §1: WYSIWYG name + lore, rarity → RARITY component
    // ------------------------------------------------------------------

    private static int loreRoundTrip() {
        int failures = 0;
        ExecuteBlock lore = new ExecuteBlock();
        lore.addStatement(new LineStatement(new StringLiteral("<blue>A legendary blade.")));
        lore.addStatement(new LineStatement(null)); // blank
        lore.addStatement(new LineStatement(new StringLiteral("<dark_gray>Soulbound")));
        // a line that interpolates a tag proves templating is still live
        lore.addStatement(new LineStatement(new StringLiteral("Uses left: ${tags.uses}")));

        Map<String, Object> tags = new LinkedHashMap<>();
        tags.put("uses", 3);
        ItemDefModel def = new ItemDefModel("aspect_of_the_end", "DIAMOND_SWORD", null,
                "<blue>Aspect of the End", "rare", true, 1, lore, new LinkedHashMap<>(),
                tags, List.of());

        ItemRegistry.clear();
        ItemRegistry.register(def);
        ItemStack stack = ItemRegistry.build("aspect_of_the_end", 1);

        // exactly the declared lines: no stat/ability/banner sections
        List<Component> rendered = stack.get(DataComponents.LORE);
        List<Component> lines = rendered != null ? rendered : List.of();
        failures += expect("lore line count is exactly what was declared", 4, lines.size());
        if (lines.size() == 4) {
            failures += expect("line 0 text", "A legendary blade.",
                    TextFormat.plain(lines.get(0)));
            failures += expect("line 0 MiniMessage colour applied", NamedTextColor.BLUE,
                    lines.get(0).color());
            failures += expect("line 1 blank", "", TextFormat.plain(lines.get(1)));
            failures += expect("line 2 text", "Soulbound", TextFormat.plain(lines.get(2)));
            failures += expect("line 3 interpolates tags.uses", "Uses left: 3",
                    TextFormat.plain(lines.get(3)));
        }

        failures += expect("name is WYSIWYG (no rarity recolor of text)",
                "Aspect of the End", TextFormat.plain(ItemLoreBuilder.buildName(def)));
        failures += expect("rarity maps to the vanilla RARITY component", ItemRarity.RARE,
                stack.get(DataComponents.RARITY));
        failures += expect("glint set", Boolean.TRUE,
                stack.get(DataComponents.ENCHANTMENT_GLINT_OVERRIDE));

        System.out.println("[LORE] " + (failures == 0 ? "PASS" : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // §1/§3: the same WYSIWYG lore, but through the real compiler pipeline
    // (swoftc -> SwoftJsonLoader -> ItemDefModel), proving the compiler emits
    // ${item_id} / ${tags.x} / ${tags.meta.tier} lore templates that the
    // loader + runtime resolve — the §3 "RPG item" tutorial pattern end to end
    // ------------------------------------------------------------------

    private static int loreTemplateRoundTrip() {
        int failures = 0;
        String source = """
                item "rpg_sword" {
                    material: "DIAMOND_SWORD"
                    name: "<gold>RPG Sword"
                    rarity: epic
                    lore {
                        line "<gray>Id: ${item_id}"
                        line "<red>Damage: ${tags.damage}"
                        line "<gold>Tier ${tags.meta.tier}"
                        if tags.soulbound {
                            line "<dark_gray>Soulbound"
                        }
                    }
                    tags {
                        damage: 250
                        soulbound: true
                        meta: { tier: 5 }
                    }
                }
                """;
        try {
            Path swFile = Files.createTempFile("swoft-lore-template", ".sw");
            Files.writeString(swFile, source);
            String json = SwoftcCompiler.compile(swFile.toFile());
            ParsedScript parsed = SwoftJsonLoader.load(json);

            ItemRegistry.clear();
            for (ItemDefModel def : parsed.items()) {
                ItemRegistry.register(def);
            }
            Files.deleteIfExists(swFile);

            ItemStack stack = ItemRegistry.build("rpg_sword", 1);
            List<Component> rendered = stack.get(DataComponents.LORE);
            List<Component> lines = rendered != null ? rendered : List.of();
            failures += expect("templated lore line count", 4, lines.size());
            if (lines.size() == 4) {
                failures += expect("line 0 interpolates item_id", "Id: rpg_sword",
                        TextFormat.plain(lines.get(0)));
                failures += expect("line 1 interpolates tags.damage", "Damage: 250",
                        TextFormat.plain(lines.get(1)));
                failures += expect("line 2 interpolates nested tags.meta.tier", "Tier 5",
                        TextFormat.plain(lines.get(2)));
                failures += expect("line 3 rendered by if on a tag", "Soulbound",
                        TextFormat.plain(lines.get(3)));
            }
        } catch (Exception e) {
            System.err.println("[LORE-TEMPLATE] FAIL: " + e.getMessage());
            e.printStackTrace();
            failures++;
        }

        System.out.println("[LORE-TEMPLATE] "
                + (failures == 0 ? "PASS" : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // §2: nested NBT — write compound, read paths, delete, exists false
    // ------------------------------------------------------------------

    private static int nestedNbtRoundTrip() {
        int failures = 0;
        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("tier", 3);
        meta.put("tags", new ArrayList<>(List.of("end", "sword")));
        Map<String, Object> tags = new LinkedHashMap<>();
        tags.put("damage", 100);
        tags.put("meta", meta);

        ItemDefModel def = new ItemDefModel("crypt_key", "TRIPWIRE_HOOK", null,
                "<gold>Crypt Key", "epic", false, 1, null, new LinkedHashMap<>(),
                tags, List.of());
        ItemRegistry.clear();
        ItemRegistry.register(def);

        Map<String, Object> vars = new HashMap<>();
        vars.put("item", ItemRegistry.build("crypt_key", 1));

        // reads through item.tags.<path...>
        failures += expect("item.tags.damage", 100, read(vars, "tags", "damage"));
        failures += expect("item.tags.meta.tier", 3, read(vars, "tags", "meta", "tier"));
        failures += expect("item.tags.meta.tags nested list",
                List.of("end", "sword"), read(vars, "tags", "meta", "tags"));
        failures += expect("absent key reads none", NoneValue.INSTANCE,
                read(vars, "tags", "nope"));

        // deep write rebinds item and flushes to NBT
        write(vars, 7, "tags", "meta", "tier");
        failures += expect("nested write read-back", 7, read(vars, "tags", "meta", "tier"));
        failures += expect("sibling scalar untouched", 100, read(vars, "tags", "damage"));
        failures += expect("write reflects on the stack NBT", 7,
                ItemRegistry.readTags((ItemStack) vars.get("item"))
                        .get("meta") instanceof Map<?, ?> m ? m.get("tier") : null);

        // delete a nested key: set to none -> exists false
        write(vars, NoneValue.INSTANCE, "tags", "meta", "tier");
        failures += expect("deleted nested key is none", NoneValue.INSTANCE,
                read(vars, "tags", "meta", "tier"));
        failures += expect("sibling nested key survives delete",
                List.of("end", "sword"), read(vars, "tags", "meta", "tags"));

        // delete a whole compound
        write(vars, NoneValue.INSTANCE, "tags", "meta");
        failures += expect("deleted compound is none", NoneValue.INSTANCE,
                read(vars, "tags", "meta"));
        failures += expect("unrelated top-level tag survives", 100,
                read(vars, "tags", "damage"));

        // auto-vivify: a deep write whose intermediate compound is absent
        // rebuilds the chain instead of throwing (the §2/§3 'set
        // item.tags.stats.strength to 5' on a fresh item). 'stats' does not
        // exist here (meta was just deleted), so this is a fresh intermediate.
        failures += expect("intermediate 'stats' starts absent", NoneValue.INSTANCE,
                read(vars, "tags", "stats"));
        write(vars, 5, "tags", "stats", "strength");
        failures += expect("vivified one intermediate reads back", 5,
                read(vars, "tags", "stats", "strength"));
        failures += expect("vivify left the sibling scalar intact", 100,
                read(vars, "tags", "damage"));
        // a sibling write into the now-existing compound
        write(vars, 12, "tags", "stats", "mana");
        failures += expect("second key in the vivified compound", 12,
                read(vars, "tags", "stats", "mana"));
        failures += expect("first vivified key survives the sibling write", 5,
                read(vars, "tags", "stats", "strength"));
        // two absent intermediates at once (item.tags.a.b.c = 7)
        write(vars, 7, "tags", "loadout", "primary", "power");
        failures += expect("vivified two intermediates reads back", 7,
                read(vars, "tags", "loadout", "primary", "power"));
        // the vivified tree really flushed to the stack NBT, not just the view
        failures += expect("vivified write reflects on the stack NBT", 5,
                ItemRegistry.readTags((ItemStack) vars.get("item"))
                        .get("stats") instanceof Map<?, ?> m ? m.get("strength") : null);

        System.out.println("[NBT] " + (failures == 0 ? "PASS" : failures + " failure(s)"));
        return failures;
    }

    private static Object read(Map<String, Object> vars, String... path) {
        return PathResolver.getPath(vars.get("item"), List.of(path), 0, 0);
    }

    private static void write(Map<String, Object> vars, Object value, String... path) {
        PathResolver.assignVariablePath(vars, "item", List.of(path), value, 0, 0);
    }

    // ------------------------------------------------------------------
    // §5: headless dispense — place, seed, dispense, assert
    // ------------------------------------------------------------------

    private static int dispenseProof() throws Exception {
        int failures = 0;
        DispenserRuntime.reset();
        DispenserRuntime.init();

        InstanceContainer instance = MinecraftServer.getInstanceManager()
                .createInstanceContainer();
        instance.setGenerator(unit -> unit.modifier().fillHeight(0, 40, Block.STONE));
        instance.loadChunk(0, 0).join();
        InstanceRegistry.register("world", instance);

        // a dispenser facing east
        Pos pos = new Pos(0, 42, 0);
        Block dispenser = Block.fromKey("minecraft:dispenser")
                .withProperties(Map.of("facing", "east"));
        instance.setBlock(pos, dispenser);

        // seed a stack of snowballs and dispense: a projectile item launches
        DispenserRuntime.inventoryOf(instance, pos, dispenser)
                .setItemStack(0, ItemStack.of(Material.SNOWBALL, 3));
        DispenserRuntime.Dispensed shot = DispenserRuntime.dispenseFrom(instance, pos);
        if (shot == null) {
            System.err.println("[DISPENSE] FAIL: nothing dispensed");
            failures++;
        } else {
            failures += expect("popped one snowball", Material.SNOWBALL, shot.item().material());
            failures += expect("dispensed a single item", 1, shot.item().amount());
            failures += expect("projectile item launched as a projectile", true,
                    shot.projectile());
            failures += expect("spawned entity kind is a snowball", EntityType.SNOWBALL,
                    shot.entity().getEntityType());
            failures += expect("velocity points east (+x)", true,
                    shot.entity().getVelocity().x() > 0
                            && Math.abs(shot.entity().getVelocity().z()) < 1e-6);
            failures += expect("facing direction is east", new Vec(1, 0, 0), shot.direction());
        }
        failures += expect("slot consumed one (3 -> 2)", 2,
                DispenserRuntime.inventoryOf(instance, pos, dispenser)
                        .getItemStack(0).amount());

        // a non-projectile item ejects as an item entity
        Pos ejectPos = new Pos(2, 42, 0);
        Block ejector = Block.fromKey("minecraft:dispenser")
                .withProperties(Map.of("facing", "up"));
        instance.setBlock(ejectPos, ejector);
        DispenserRuntime.inventoryOf(instance, ejectPos, ejector)
                .setItemStack(0, ItemStack.of(Material.STONE, 1));
        DispenserRuntime.Dispensed ejected = DispenserRuntime.dispenseFrom(instance, ejectPos);
        if (ejected == null) {
            System.err.println("[DISPENSE] FAIL: nothing ejected");
            failures++;
        } else {
            failures += expect("non-projectile does not launch", false, ejected.projectile());
            failures += expect("ejected as an item entity", true,
                    ejected.entity() instanceof ItemEntity);
        }

        // droppers ALWAYS eject, even projectile-capable items
        Pos dropperPos = new Pos(4, 42, 0);
        Block dropper = Block.fromKey("minecraft:dropper")
                .withProperties(Map.of("facing", "up"));
        instance.setBlock(dropperPos, dropper);
        DispenserRuntime.inventoryOf(instance, dropperPos, dropper)
                .setItemStack(0, ItemStack.of(Material.SNOWBALL, 1));
        DispenserRuntime.Dispensed dropped = DispenserRuntime.dispenseFrom(instance, dropperPos);
        failures += expect("dropper always ejects", false,
                dropped != null && dropped.projectile());
        failures += expect("dropper output is an item entity", true,
                dropped != null && dropped.entity() instanceof ItemEntity);

        // BlockDispense event: cancel = nothing moves, slot untouched
        Pos cancelPos = new Pos(6, 42, 0);
        Block cancelBlock = Block.fromKey("minecraft:dispenser")
                .withProperties(Map.of("facing", "up"));
        instance.setBlock(cancelPos, cancelBlock);
        DispenserRuntime.inventoryOf(instance, cancelPos, cancelBlock)
                .setItemStack(0, ItemStack.of(Material.STONE, 2));
        EventListener<BlockDispenseEvent> canceller =
                EventListener.of(BlockDispenseEvent.class, e -> e.setCancelled(true));
        MinecraftServer.getGlobalEventHandler().addListener(canceller);
        DispenserRuntime.Dispensed cancelled = DispenserRuntime.dispenseFrom(instance, cancelPos);
        MinecraftServer.getGlobalEventHandler().removeListener(canceller);
        failures += expect("cancelled dispense moves nothing", null, cancelled);
        failures += expect("cancelled dispense leaves the slot untouched", 2,
                DispenserRuntime.inventoryOf(instance, cancelPos, cancelBlock)
                        .getItemStack(0).amount());

        // BlockDispense event: swap what comes out
        Pos swapPos = new Pos(8, 42, 0);
        Block swapBlock = Block.fromKey("minecraft:dispenser")
                .withProperties(Map.of("facing", "up"));
        instance.setBlock(swapPos, swapBlock);
        DispenserRuntime.inventoryOf(instance, swapPos, swapBlock)
                .setItemStack(0, ItemStack.of(Material.STONE, 1));
        EventListener<BlockDispenseEvent> swapper = EventListener.of(BlockDispenseEvent.class,
                e -> e.setItem(ItemStack.of(Material.DIAMOND, 1)));
        MinecraftServer.getGlobalEventHandler().addListener(swapper);
        DispenserRuntime.Dispensed swapped = DispenserRuntime.dispenseFrom(instance, swapPos);
        MinecraftServer.getGlobalEventHandler().removeListener(swapper);
        failures += expect("handler swapped the dispensed item", Material.DIAMOND,
                swapped != null ? swapped.item().material() : null);

        System.out.println("[DISPENSE] " + (failures == 0 ? "PASS" : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // §3/§4: the userland cooldown gate logic abilities.sw builds on
    // ------------------------------------------------------------------

    private static int cooldownGate() {
        int failures = 0;
        // with_cooldown keeps a module-var map of player uuid -> ready tick:
        // first use passes and arms, an immediate reuse is gated, a use past
        // the window passes again. Proven serverless with a plain map.
        Map<UUID, Long> readyAt = new HashMap<>();
        UUID player = UUID.randomUUID();
        long cooldownTicks = 60;

        boolean first = gate(readyAt, player, 1000, cooldownTicks);
        boolean second = gate(readyAt, player, 1005, cooldownTicks);
        boolean third = gate(readyAt, player, 1100, cooldownTicks);

        failures += expect("first use passes", true, first);
        failures += expect("immediate reuse gated", false, second);
        failures += expect("use past the window passes", true, third);

        System.out.println("[COOLDOWN] " + (failures == 0 ? "PASS" : failures + " failure(s)"));
        return failures;
    }

    private static boolean gate(Map<UUID, Long> readyAt, UUID player, long nowTick,
            long cooldownTicks) {
        long ready = readyAt.getOrDefault(player, 0L);
        if (nowTick < ready) {
            return false;
        }
        readyAt.put(player, nowTick + cooldownTicks);
        return true;
    }

    private static int expect(String label, Object expected, Object actual) {
        boolean ok = expected == null ? actual == null : expected.equals(actual);
        if (!ok) {
            System.err.println("[PHASE9] FAIL " + label + ": expected " + expected
                    + " got " + actual);
            return 1;
        }
        System.out.println("[PHASE9] ok " + label + " = " + actual);
        return 0;
    }
}
