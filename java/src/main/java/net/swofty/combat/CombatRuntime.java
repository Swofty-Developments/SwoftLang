package net.swofty.combat;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import net.minestom.server.entity.Entity;
import net.minestom.server.entity.LivingEntity;
import net.minestom.server.entity.attribute.Attribute;
import net.minestom.server.entity.attribute.AttributeInstance;
import net.minestom.server.entity.attribute.AttributeModifier;
import net.minestom.server.entity.attribute.AttributeOperation;
import net.minestom.server.entity.damage.DamageType;
import net.minestom.server.potion.PotionEffect;
import net.minestom.server.potion.TimedPotion;
import net.minestom.server.registry.RegistryKey;
import net.swofty.ScriptError;
import net.swofty.displays.SwoftDisplay;
import net.swofty.runtime.Values;

/**
 * Shared resolvers + runtime hops for the W-pvp surface after the free
 * functions became direct entity properties (armor / set max_health /
 * invulnerable_ticks / active_effects) and English statement verbs (damage /
 * knock / apply / remove / shoot / add|remove modifier). Every mechanic here
 * points at the SAME Minestom runtime the old builtins called; this class only
 * concentrates the name-to-constant mapping so the property table and the
 * statement nodes can both reach it.
 */
public final class CombatRuntime {

    private CombatRuntime() {
    }

    /**
     * The entity ATTRIBUTE keys exposed as direct rw Double properties. Kept in
     * sync with Registry.combat_attribute_names. "gravity" and "max_health" are
     * intentionally omitted: they already exist as base entity/living rows (a
     * boolean gravity flag and the rw max_health double) that keep priority, so
     * re-registering them as plain attribute doubles would shadow those rows.
     */
    public static final String[] ATTRIBUTE_PROPERTY_NAMES = {
            "armor", "armor_toughness", "attack_damage", "attack_knockback", "attack_speed",
            "knockback_resistance", "max_absorption", "absorption", "movement_speed",
            "fall_damage_multiplier", "safe_fall_distance", "sweeping_damage_ratio", "flying_speed",
            "follow_range", "jump_strength", "scale", "step_height", "luck",
            "block_interaction_range", "entity_interaction_range", "explosion_knockback_resistance",
    };

    /** Any script value that IS or WRAPS a Minestom entity. */
    public static Entity asEntity(Object value, String what) {
        if (value instanceof Entity entity) {
            return entity;
        }
        if (value instanceof SwoftDisplay display) {
            return display.entity();
        }
        throw new ScriptError(what + " expects an entity, got: "
                + Values.displayString(value));
    }

    /** An entity value that is living (attributes/effects live on LivingEntity). */
    public static LivingEntity asLiving(Object value, String what) {
        Entity entity = asEntity(value, what);
        if (entity instanceof LivingEntity living) {
            return living;
        }
        throw new ScriptError(what + " expects a living entity (player, mob, ...), got: "
                + entity.getEntityType().key().asString());
    }

    /** The live potion keys currently on an entity, as bare snake_case names. */
    public static List<Object> activeEffects(Entity entity) {
        List<Object> effects = new ArrayList<>();
        for (TimedPotion timed : entity.getActiveEffects()) {
            effects.add(timed.potion().effect().key().value());
        }
        return effects;
    }

    /**
     * Map a snake_case attribute key from a script to a Minestom Attribute
     * constant. Kept in sync with Registry.combat_attribute_names. "absorption"
     * is an alias for MAX_ABSORPTION (no plain ABSORPTION attribute exists).
     */
    public static Attribute attributeFromName(String raw) {
        String key = raw.trim().toLowerCase(Locale.ROOT);
        int colon = key.indexOf(':');
        if (colon >= 0) {
            key = key.substring(colon + 1);
        }
        return switch (key) {
            case "armor" -> Attribute.ARMOR;
            case "armor_toughness" -> Attribute.ARMOR_TOUGHNESS;
            case "attack_damage" -> Attribute.ATTACK_DAMAGE;
            case "attack_knockback" -> Attribute.ATTACK_KNOCKBACK;
            case "attack_speed" -> Attribute.ATTACK_SPEED;
            case "knockback_resistance" -> Attribute.KNOCKBACK_RESISTANCE;
            case "max_health" -> Attribute.MAX_HEALTH;
            case "max_absorption", "absorption" -> Attribute.MAX_ABSORPTION;
            case "movement_speed" -> Attribute.MOVEMENT_SPEED;
            case "fall_damage_multiplier" -> Attribute.FALL_DAMAGE_MULTIPLIER;
            case "safe_fall_distance" -> Attribute.SAFE_FALL_DISTANCE;
            case "sweeping_damage_ratio" -> Attribute.SWEEPING_DAMAGE_RATIO;
            case "flying_speed" -> Attribute.FLYING_SPEED;
            case "follow_range" -> Attribute.FOLLOW_RANGE;
            case "jump_strength" -> Attribute.JUMP_STRENGTH;
            case "scale" -> Attribute.SCALE;
            case "gravity" -> Attribute.GRAVITY;
            case "step_height" -> Attribute.STEP_HEIGHT;
            case "luck" -> Attribute.LUCK;
            case "block_interaction_range" -> Attribute.BLOCK_INTERACTION_RANGE;
            case "entity_interaction_range" -> Attribute.ENTITY_INTERACTION_RANGE;
            case "explosion_knockback_resistance" -> Attribute.EXPLOSION_KNOCKBACK_RESISTANCE;
            default -> throw new ScriptError("unknown attribute '" + raw + "'");
        };
    }

    /**
     * Resolve a script potion-effect key (e.g. "speed", "minecraft:strength") to
     * a Minestom PotionEffect via the registry. Bare names are namespaced to
     * "minecraft:". Kept in sync with Registry.potion_effect_names.
     */
    public static PotionEffect potionEffectFromName(String raw) {
        String key = raw.trim().toLowerCase(Locale.ROOT);
        if (key.indexOf(':') < 0) {
            key = "minecraft:" + key;
        }
        PotionEffect effect = PotionEffect.fromKey(key);
        if (effect == null) {
            throw new ScriptError("unknown potion effect '" + raw + "'");
        }
        return effect;
    }

    /**
     * Build a RegistryKey&lt;DamageType&gt; from a script damage-type key (e.g.
     * "player_attack", "minecraft:magic"). Bare names are namespaced to
     * "minecraft:". Kept in sync with Registry.damage_type_names.
     */
    public static RegistryKey<DamageType> damageTypeKeyFromName(String raw) {
        String key = raw.trim().toLowerCase(Locale.ROOT);
        if (key.indexOf(':') < 0) {
            key = "minecraft:" + key;
        }
        return RegistryKey.unsafeOf(key);
    }

    /**
     * Map a script operation name to an AttributeOperation. The vanilla enum is
     * ADD_VALUE / ADD_MULTIPLIED_BASE / ADD_MULTIPLIED_TOTAL; friendly aliases
     * (add, multiply_base, multiply_total) are accepted too.
     */
    public static AttributeOperation attributeOperationFromName(String raw) {
        String op = raw.trim().toLowerCase(Locale.ROOT);
        return switch (op) {
            case "add_value", "add" -> AttributeOperation.ADD_VALUE;
            case "add_multiplied_base", "multiply_base" -> AttributeOperation.ADD_MULTIPLIED_BASE;
            case "add_multiplied_total", "multiply_total" -> AttributeOperation.ADD_MULTIPLIED_TOTAL;
            default -> throw new ScriptError("unknown attribute operation '" + raw
                    + "' (valid: add_value, add_multiplied_base, add_multiplied_total)");
        };
    }

    /**
     * Remove any modifier on this attribute whose id matches {@code id}
     * (comparing both the bare value and the namespaced key form), so
     * add/remove round-trips regardless of the namespace the key was minted in.
     */
    public static void removeModifierById(AttributeInstance inst, String id) {
        String needle = id.trim().toLowerCase(Locale.ROOT);
        for (AttributeModifier mod : new ArrayList<>(inst.getModifiers())) {
            net.kyori.adventure.key.Key key = mod.id();
            if (key.value().equalsIgnoreCase(needle)
                    || key.asString().equalsIgnoreCase(needle)) {
                inst.removeModifier(key);
            }
        }
    }

    /**
     * Coerce a user modifier id into a valid Adventure key value
     * ({@code [a-z0-9_.-]}). Uppercase folds to lowercase, spaces and other
     * characters become underscores; add and remove use the same normalization
     * so ids round-trip. An id that normalizes to empty is rejected.
     */
    public static String normalizeModifierId(String raw) {
        StringBuilder sb = new StringBuilder(raw.length());
        for (char c : raw.trim().toLowerCase(Locale.ROOT).toCharArray()) {
            if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')
                    || c == '_' || c == '.' || c == '-') {
                sb.append(c);
            } else {
                sb.append('_');
            }
        }
        if (sb.length() == 0) {
            throw new ScriptError("attribute modifier id '" + raw + "' is empty after "
                    + "normalization; use letters, digits, '_', '.', or '-'");
        }
        return sb.toString();
    }
}
