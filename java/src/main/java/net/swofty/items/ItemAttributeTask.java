package net.swofty.items;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.kyori.adventure.key.Key;
import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.EquipmentSlot;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.attribute.Attribute;
import net.minestom.server.entity.attribute.AttributeInstance;
import net.minestom.server.entity.attribute.AttributeModifier;
import net.minestom.server.entity.attribute.AttributeOperation;
import net.minestom.server.event.player.PlayerDisconnectEvent;
import net.minestom.server.item.ItemStack;
import net.minestom.server.timer.TaskSchedule;
import net.swofty.model.ItemDefModel;

/**
 * The attributes{} equipment-scan task (design 5A): every 10 ticks, for
 * each online player, computes the wanted Minestom attribute modifiers from
 * the custom items in main hand + the four armor slots, then diffs against
 * what is currently applied. Modifier ids are deterministic namespaced keys
 * ("swoftlang:item/&lt;id&gt;/&lt;slot&gt;/&lt;attr&gt;") so re-application is an upsert
 * and removal is exact.
 */
public final class ItemAttributeTask {
    private static final EquipmentSlot[] SCANNED_SLOTS = {
            EquipmentSlot.MAIN_HAND, EquipmentSlot.HELMET, EquipmentSlot.CHESTPLATE,
            EquipmentSlot.LEGGINGS, EquipmentSlot.BOOTS,
    };

    /** player uuid -> (modifier id -> attribute it was applied to) */
    private static final Map<UUID, Map<String, Attribute>> APPLIED = new ConcurrentHashMap<>();
    private static boolean initialized = false;

    private ItemAttributeTask() {
    }

    public static synchronized void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        MinecraftServer.getSchedulerManager().scheduleTask(ItemAttributeTask::scanAll,
                TaskSchedule.tick(10), TaskSchedule.tick(10));
        MinecraftServer.getGlobalEventHandler().addListener(PlayerDisconnectEvent.class,
                event -> APPLIED.remove(event.getPlayer().getUuid()));
    }

    private static void scanAll() {
        for (Player player : MinecraftServer.getConnectionManager().getOnlinePlayers()) {
            try {
                scan(player);
            } catch (Exception e) {
                System.err.println("Error in item attribute scan for "
                        + player.getUsername() + ": " + e.getMessage());
            }
        }
    }

    static void scan(Player player) {
        Map<String, WantedModifier> wanted = wantedModifiers(player);
        Map<String, Attribute> applied = APPLIED.computeIfAbsent(player.getUuid(),
                uuid -> new ConcurrentHashMap<>());

        // Remove stale modifiers first
        for (Map.Entry<String, Attribute> entry : Map.copyOf(applied).entrySet()) {
            if (!wanted.containsKey(entry.getKey())) {
                player.getAttribute(entry.getValue()).removeModifier(Key.key(entry.getKey()));
                applied.remove(entry.getKey());
            }
        }
        // Apply missing ones (addModifier is a keyed upsert in the pinned jar)
        for (Map.Entry<String, WantedModifier> entry : wanted.entrySet()) {
            if (!applied.containsKey(entry.getKey())) {
                AttributeInstance instance = player.getAttribute(entry.getValue().attribute());
                instance.addModifier(new AttributeModifier(entry.getKey(),
                        entry.getValue().amount(), AttributeOperation.ADD_VALUE));
                applied.put(entry.getKey(), entry.getValue().attribute());
            }
        }
    }

    record WantedModifier(Attribute attribute, double amount) {
    }

    static Map<String, WantedModifier> wantedModifiers(Player player) {
        Map<String, WantedModifier> wanted = new HashMap<>();
        for (EquipmentSlot slot : SCANNED_SLOTS) {
            ItemStack stack = player.getEquipment(slot);
            String id = ItemRegistry.customId(stack);
            if (id == null) {
                continue;
            }
            ItemDefModel def = ItemRegistry.get(id);
            if (def == null || def.attributes().isEmpty()) {
                continue;
            }
            for (Map.Entry<String, Double> attr : def.attributes().entrySet()) {
                Attribute attribute = toAttribute(attr.getKey());
                if (attribute == null) {
                    continue;
                }
                String modifierId = "swoftlang:item/" + id + "/"
                        + slot.name().toLowerCase() + "/" + attr.getKey();
                wanted.put(modifierId, new WantedModifier(attribute, attr.getValue()));
            }
        }
        return wanted;
    }

    /** attributes{} keys onto real pinned-jar Attribute constants. */
    static Attribute toAttribute(String key) {
        return switch (key.toLowerCase()) {
            case "speed" -> Attribute.MOVEMENT_SPEED;
            case "max_health" -> Attribute.MAX_HEALTH;
            case "attack_damage" -> Attribute.ATTACK_DAMAGE;
            case "attack_speed" -> Attribute.ATTACK_SPEED;
            case "armor" -> Attribute.ARMOR;
            case "knockback_resistance" -> Attribute.KNOCKBACK_RESISTANCE;
            default -> null;
        };
    }
}
