package net.swofty.items;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

import net.kyori.adventure.nbt.CompoundBinaryTag;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.PlayerSkin;
import net.minestom.server.component.DataComponents;
import net.minestom.server.item.ItemStack;
import net.minestom.server.item.Material;
import net.minestom.server.item.component.AttributeList;
import net.minestom.server.network.player.ResolvableProfile;
import net.minestom.server.tag.Tag;
import net.swofty.ScriptError;
import net.swofty.props.Coercions;

/**
 * Registry of item declarations plus the generic tag-based identity round
 * trip (phase 9). Identity is Tag.String("swoft_item_id"); the freeform
 * tags{} tree lives in one nested NBT compound Tag.NBT("swoft_tags").
 * Appearance is WYSIWYG: the declared name is the name, the declared lore
 * is the lore, and rarity: maps to the vanilla RARITY component. There is
 * no auto-assembled lore and no Hypixel stat/ability machinery.
 */
public final class ItemRegistry {
    public static final Tag<String> ITEM_ID_TAG = Tag.String("swoft_item_id");
    /** The whole freeform tag tree as one nested NBT compound. */
    public static final Tag<net.kyori.adventure.nbt.BinaryTag> TAGS_NBT =
            Tag.NBT("swoft_tags");

    /** The only real Minestom attributes an attributes{} block may carry. */
    public static final Set<String> ALLOWED_ATTRIBUTES = Set.of(
            "speed", "max_health", "attack_damage", "attack_speed", "armor",
            "knockback_resistance");

    private static final Map<String, net.swofty.model.ItemDefModel> DEFS =
            new ConcurrentHashMap<>();
    private static final List<String> ORDER = new CopyOnWriteArrayList<>();

    private ItemRegistry() {
    }

    public static void clear() {
        DEFS.clear();
        ORDER.clear();
    }

    /**
     * Register one declaration. Structural problems (bad rarity/attribute
     * names, material+skull conflicts, duplicate ids) are load errors:
     * reported and the declaration skipped.
     */
    public static void register(net.swofty.model.ItemDefModel def) {
        try {
            validate(def);
        } catch (ScriptError e) {
            System.err.println("Error: item '" + def.id() + "': " + e.getMessage());
            return;
        }
        if (DEFS.putIfAbsent(def.id(), def) != null) {
            System.err.println("Error: duplicate item id '" + def.id() + "' - keeping the first");
            return;
        }
        ORDER.add(def.id());
    }

    private static void validate(net.swofty.model.ItemDefModel def) {
        // item ids feed namespaced keys ("swoftlang:item/<id>/<slot>/<attr>"
        // in the attribute scan) whose adventure Key path only permits
        // [a-z0-9_.-]: reject anything else at registration (the OCaml
        // checker enforces the same charset at compile time)
        if (def.id() == null || def.id().isEmpty()
                || !def.id().matches("[a-z0-9_.-]+")) {
            throw new ScriptError("item id must use only lowercase [a-z0-9_.-] characters"
                    + " (it becomes part of a namespaced key)");
        }
        if ((def.material() == null) == (def.skull() == null)) {
            throw new ScriptError("exactly one of material: or skull: is required");
        }
        if (def.material() != null) {
            Coercions.toMaterial(def.material());
        }
        if (def.rarity() != null) {
            Rarity.parse(def.rarity());
        }
        for (String attribute : def.attributes().keySet()) {
            if (!ALLOWED_ATTRIBUTES.contains(attribute.toLowerCase())) {
                throw new ScriptError("unknown attribute '" + attribute
                        + "' in attributes{} (valid: " + String.join(", ", ALLOWED_ATTRIBUTES) + ")");
            }
        }
    }

    public static net.swofty.model.ItemDefModel get(String id) {
        return DEFS.get(id);
    }

    public static net.swofty.model.ItemDefModel require(String id) {
        net.swofty.model.ItemDefModel def = DEFS.get(id);
        if (def == null) {
            throw new ScriptError("unknown item id '" + id + "'");
        }
        return def;
    }

    /** Declaration ids in registration order (harness display). */
    public static List<String> ids() {
        return List.copyOf(ORDER);
    }

    /** Build a fresh stack with declared tag defaults and default amount. */
    public static ItemStack build(String id, int amount) {
        net.swofty.model.ItemDefModel def = require(id);
        int effective = amount > 0 ? amount : Math.max(1, def.amount());
        return materialize(def, deepCopy(def.tags()), effective);
    }

    /**
     * The single projection pipeline: identity + freeform tags into the
     * nested NBT compound, then name/lore/rarity/glint/skull rendered from
     * the definition. Vanilla attribute tooltip lines are suppressed (empty
     * AttributeList); the real attributes{} apply via the equipment-scan
     * task instead.
     */
    public static ItemStack materialize(net.swofty.model.ItemDefModel def,
            Map<String, Object> tagTree, int amount) {
        Material material = def.skull() != null
                ? Material.PLAYER_HEAD
                : Coercions.toMaterial(def.material());
        ItemStack.Builder builder = ItemStack.builder(material)
                .amount(Math.max(1, amount));

        builder.set(ITEM_ID_TAG, def.id());
        if (!tagTree.isEmpty()) {
            builder.set(TAGS_NBT, NbtCodec.toCompound(tagTree));
        }

        builder.set(DataComponents.CUSTOM_NAME, ItemLoreBuilder.buildName(def));
        List<net.kyori.adventure.text.Component> lore = ItemLoreBuilder.buildLore(def, tagTree);
        if (!lore.isEmpty()) {
            builder.set(DataComponents.LORE, lore);
        }
        if (def.rarity() != null) {
            builder.set(DataComponents.RARITY, Rarity.parse(def.rarity()).component());
        }
        if (def.glint()) {
            builder.set(DataComponents.ENCHANTMENT_GLINT_OVERRIDE, true);
        }
        if (def.skull() != null) {
            builder.set(DataComponents.PROFILE,
                    new ResolvableProfile(new PlayerSkin(texturesBase64(def.skull()), null)));
        }
        // Empty modifier list overrides the material's default attribute
        // tooltip lines (real attributes{} apply via the equipment-scan task).
        builder.set(DataComponents.ATTRIBUTE_MODIFIERS, AttributeList.EMPTY);
        return builder.build();
    }

    /** skull: accepts a raw texture hash or an already-encoded base64 blob. */
    private static String texturesBase64(String skull) {
        if (skull.startsWith("eyJ") || skull.length() > 100) {
            return skull;
        }
        String json = "{\"textures\":{\"SKIN\":{\"url\":\"http://textures.minecraft.net/texture/"
                + skull + "\"}}}";
        return Base64.getEncoder().encodeToString(json.getBytes(StandardCharsets.UTF_8));
    }

    /** The custom-item discriminator; null for vanilla/air stacks. */
    public static String customId(ItemStack stack) {
        if (stack == null || stack.isAir()) {
            return null;
        }
        return stack.getTag(ITEM_ID_TAG);
    }

    /**
     * The nested freeform tag tree stored on a stack. Works on ANY
     * ItemStack: absent NBT is an empty tree. Nested compounds arrive as
     * Maps and lists as Lists (phase 9 §2).
     */
    public static Map<String, Object> readTags(ItemStack stack) {
        net.kyori.adventure.nbt.BinaryTag raw = stack.getTag(TAGS_NBT);
        if (raw instanceof CompoundBinaryTag compound) {
            return NbtCodec.fromCompound(compound);
        }
        return new LinkedHashMap<>();
    }

    /**
     * Rewrite the entire freeform tag tree of a stack and re-render its
     * display projection (registry items re-render name/lore so lore
     * templating on ${tags.x} stays live; plain stacks just carry the NBT).
     */
    public static ItemStack setTags(ItemStack stack, Map<String, Object> tree) {
        String id = customId(stack);
        if (id != null) {
            net.swofty.model.ItemDefModel def = get(id);
            if (def != null) {
                return materialize(def, tree, stack.amount());
            }
        }
        if (tree.isEmpty()) {
            return stack.withTag(TAGS_NBT, null);
        }
        return stack.withTag(TAGS_NBT, NbtCodec.toCompound(tree));
    }

    /**
     * Merge top-level tag values onto a stack (harness/back-compat helper):
     * the given keys overwrite, the rest of the tree is preserved.
     */
    public static ItemStack withTags(ItemStack stack, Map<String, Object> newValues) {
        Map<String, Object> merged = readTags(stack);
        merged.putAll(newValues);
        return setTags(stack, merged);
    }

    /** give item "id" to player [amount N] */
    public static void give(Player player, String id, int amount) {
        ItemStack stack = build(id, amount);
        boolean added = player.getInventory().addItemStack(stack);
        if (!added) {
            System.err.println("Warning: inventory full, item '" + id + "' not given to "
                    + player.getUsername());
        }
    }

    public static Collection<net.swofty.model.ItemDefModel> all() {
        return DEFS.values();
    }

    /** Deep copy of a nested tag tree so registry defaults are never mutated. */
    @SuppressWarnings("unchecked")
    public static Object deepCopy(Object value) {
        if (value instanceof Map<?, ?> map) {
            Map<String, Object> copy = new LinkedHashMap<>();
            for (Map.Entry<?, ?> entry : map.entrySet()) {
                copy.put(String.valueOf(entry.getKey()), deepCopy(entry.getValue()));
            }
            return copy;
        }
        if (value instanceof List<?> list) {
            java.util.List<Object> copy = new java.util.ArrayList<>();
            for (Object element : list) {
                copy.add(deepCopy(element));
            }
            return copy;
        }
        return value;
    }

    @SuppressWarnings("unchecked")
    public static Map<String, Object> deepCopy(Map<String, Object> tree) {
        return (Map<String, Object>) deepCopy((Object) tree);
    }
}
