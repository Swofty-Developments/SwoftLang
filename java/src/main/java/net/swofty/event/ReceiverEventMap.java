package net.swofty.event;

import java.util.HashMap;
import java.util.Map;

/**
 * The canonical native/curated event a receiver method dispatches on, keyed by
 * {@code (receiverType, method)}. This is the runtime mirror of the compiler's
 * {@code receiver_method_event} table (registry.ml): it lets a struct-instance
 * receiver (§4) resolve the same event a global {@code Player { on_death }}
 * receiver would compile down to, so the struct-instance dispatcher can attach a
 * listener to exactly that event.
 *
 * <p>Methods whose dispatch has no distinct catalog event — they ride the
 * inline-handler / NPC / hologram / mob-forwarding runtimes (on_click,
 * on_target, on_touch, on_break, …) — are simply absent (null), and the
 * struct-instance dispatcher skips them with a warning: a reactive struct field
 * only reacts to events with a real native subject.
 */
public final class ReceiverEventMap {

    private static final Map<String, String> TABLE = build();

    private ReceiverEventMap() {
    }

    /** The event name for a receiver method, or null when it has no catalog event. */
    public static String eventFor(String receiver, String method) {
        if (receiver == null || method == null) {
            return null;
        }
        return TABLE.get(receiver + "#" + method);
    }

    private static void put(Map<String, String> t, String receiver, String method, String event) {
        t.put(receiver + "#" + method, event);
    }

    private static Map<String, String> build() {
        Map<String, String> t = new HashMap<>();

        // --- Player ---
        put(t, "Player", "on_join", "PlayerSpawn");
        put(t, "Player", "on_quit", "PlayerDisconnect");
        put(t, "Player", "on_loaded", "PlayerLoaded");
        put(t, "Player", "on_chat", "PlayerChat");
        put(t, "Player", "on_move", "PlayerMove");
        put(t, "Player", "on_death", "PlayerDeath");
        put(t, "Player", "on_respawn", "PlayerRespawn");
        put(t, "Player", "on_command", "PlayerCommand");
        put(t, "Player", "on_break_block", "PlayerBlockBreak");
        put(t, "Player", "on_place_block", "PlayerBlockPlace");
        put(t, "Player", "on_interact_block", "PlayerBlockInteract");
        put(t, "Player", "on_use_item", "VanillaUseItem");
        put(t, "Player", "on_use_item_on_block", "PlayerUseItemOnBlock");
        put(t, "Player", "on_start_digging", "PlayerStartDigging");
        put(t, "Player", "on_finish_digging", "PlayerFinishDigging");
        put(t, "Player", "on_cancel_digging", "PlayerCancelDigging");
        put(t, "Player", "on_change_held_slot", "PlayerChangeHeldSlot");
        put(t, "Player", "on_swap_item", "PlayerSwapItem");
        put(t, "Player", "on_gamemode_change", "PlayerGameModeChange");
        put(t, "Player", "on_start_sprinting", "PlayerStartSprinting");
        put(t, "Player", "on_stop_sprinting", "PlayerStopSprinting");
        put(t, "Player", "on_start_flying", "PlayerStartFlying");
        put(t, "Player", "on_stop_flying", "PlayerStopFlying");
        put(t, "Player", "on_start_elytra", "PlayerStartFlyingWithElytra");
        put(t, "Player", "on_stop_elytra", "PlayerStopFlyingWithElytra");
        put(t, "Player", "on_interact_entity", "PlayerEntityInteract");
        put(t, "Player", "on_spectate_entity", "PlayerSpectateEntity");
        put(t, "Player", "on_teleport_to_entity", "PlayerTeleportToEntity");
        put(t, "Player", "on_pick_entity", "PlayerPickEntity");
        put(t, "Player", "on_pick_block", "PlayerPickBlock");
        put(t, "Player", "on_edit_sign", "PlayerEditSign");
        put(t, "Player", "on_edit_book", "EditBook");
        put(t, "Player", "on_anvil_input", "PlayerAnvilInput");
        put(t, "Player", "on_leave_bed", "PlayerLeaveBed");
        put(t, "Player", "on_hand_animation", "PlayerHandAnimation");
        put(t, "Player", "on_input", "PlayerInput");
        put(t, "Player", "on_tick", "PlayerTick");
        put(t, "Player", "on_tick_end", "PlayerTickEnd");
        put(t, "Player", "on_chunk_load", "PlayerChunkLoad");
        put(t, "Player", "on_chunk_unload", "PlayerChunkUnload");
        put(t, "Player", "on_skin_init", "PlayerSkinInit");
        put(t, "Player", "on_settings_change", "PlayerSettingsChange");
        put(t, "Player", "on_resource_pack_status", "PlayerResourcePackStatus");
        put(t, "Player", "on_plugin_message", "PlayerPluginMessage");
        put(t, "Player", "on_advancement_tab", "AdvancementTab");
        put(t, "Player", "on_stab", "PlayerStab");
        put(t, "Player", "on_pickup_experience", "PickupExperience");
        put(t, "Player", "on_drop_item", "ItemDrop");
        put(t, "Player", "on_pickup_item", "PickupItem");
        put(t, "Player", "on_packet_in", "PlayerPacket");
        put(t, "Player", "on_packet_out", "PlayerPacketOut");
        put(t, "Player", "on_begin_item_use", "PlayerBeginItemUse");
        put(t, "Player", "on_cancel_item_use", "PlayerCancelItemUse");
        put(t, "Player", "on_finish_item_use", "PlayerFinishItemUse");
        put(t, "Player", "on_outgoing_transfer", "OutgoingTransfer");
        put(t, "Player", "on_cast_rod", "PlayerCastRod");
        put(t, "Player", "on_fish_bite", "FishBite");
        put(t, "Player", "on_catch_fish", "PlayerCatchFish");
        put(t, "Player", "on_reel_in", "PlayerReelIn");

        // --- Entity ---
        put(t, "Entity", "on_hit", "EntityDamage");
        put(t, "Entity", "on_death", "EntityDeath");
        put(t, "Entity", "on_spawn", "EntitySpawn");
        put(t, "Entity", "on_despawn", "EntityDespawn");
        put(t, "Entity", "on_attack", "EntityAttack");
        put(t, "Entity", "on_tick", "EntityTick");
        put(t, "Entity", "on_teleport", "EntityTeleport");
        put(t, "Entity", "on_velocity", "EntityVelocity");
        put(t, "Entity", "on_shoot", "EntityShoot");
        put(t, "Entity", "on_set_fire", "EntitySetFire");
        put(t, "Entity", "on_fire_extinguish", "EntityFireExtinguish");
        put(t, "Entity", "on_item_merge", "EntityItemMerge");
        put(t, "Entity", "on_potion_add", "EntityPotionAdd");
        put(t, "Entity", "on_potion_remove", "EntityPotionRemove");
        put(t, "Entity", "on_equip", "EntityEquip");
        put(t, "Entity", "on_pickup_item", "PickupItem");

        // --- Mob (mob-filtered typed views of the entity events) ---
        put(t, "Mob", "on_hit", "MobDamage");
        put(t, "Mob", "on_death", "MobDeath");
        put(t, "Mob", "on_spawn", "MobSpawn");
        put(t, "Mob", "on_attack", "EntityAttack");
        put(t, "Mob", "on_despawn", "EntityDespawn");
        put(t, "Mob", "on_teleport", "EntityTeleport");
        put(t, "Mob", "on_shoot", "EntityShoot");
        put(t, "Mob", "on_click", "PlayerEntityInteract");

        // --- Item ---
        put(t, "Item", "on_use", "PlayerUseItem");
        put(t, "Item", "on_right_click", "VanillaUseItem");
        put(t, "Item", "on_right_click_block", "PlayerUseItemOnBlock");
        put(t, "Item", "on_left_click", "PlayerHandAnimation");
        put(t, "Item", "on_attack_entity", "EntityAttack");
        put(t, "Item", "on_consume", "PlayerFinishItemUse");
        put(t, "Item", "on_drop", "ItemDrop");
        put(t, "Item", "on_pickup", "PickupItem");
        put(t, "Item", "on_swap_to", "PlayerChangeHeldSlot");
        put(t, "Item", "on_begin_use", "PlayerBeginItemUse");
        put(t, "Item", "on_cancel_use", "PlayerCancelItemUse");
        put(t, "Item", "on_finish_use", "PlayerFinishItemUse");
        put(t, "Item", "on_equip", "EntityEquip");

        // --- Block ---
        put(t, "Block", "on_place", "PlayerBlockPlace");
        put(t, "Block", "on_break", "PlayerBlockBreak");
        put(t, "Block", "on_interact", "PlayerBlockInteract");
        put(t, "Block", "on_dispense", "BlockDispense");

        // --- Projectile ---
        put(t, "Projectile", "on_hit_block", "ProjectileCollideWithBlock");
        put(t, "Projectile", "on_hit_entity", "ProjectileCollideWithEntity");
        put(t, "Projectile", "on_uncollide", "ProjectileUncollide");

        // --- Inventory / GUI ---
        put(t, "Inventory", "on_pre_click", "InventoryPreClick");
        put(t, "Inventory", "on_click", "InventoryClick");
        put(t, "Inventory", "on_open", "InventoryOpen");
        put(t, "Inventory", "on_close", "InventoryClose");
        put(t, "Inventory", "on_button_click", "InventoryButtonClick");
        put(t, "Inventory", "on_bundle_select", "InventoryBundleItemSelect");
        put(t, "Inventory", "on_item_change", "InventoryItemChange");
        put(t, "Inventory", "on_creative_action", "CreativeInventoryAction");

        // --- World / Instance ---
        put(t, "World", "on_tick", "InstanceTick");
        put(t, "World", "on_chunk_load", "InstanceChunkLoad");
        put(t, "World", "on_chunk_unload", "InstanceChunkUnload");
        put(t, "World", "on_register", "InstanceRegister");
        put(t, "World", "on_unregister", "InstanceUnregister");
        put(t, "World", "on_section_invalidate", "InstanceSectionInvalidate");
        put(t, "World", "on_block_update", "InstanceBlockUpdate");
        put(t, "World", "on_entity_add", "AddEntityToInstance");
        put(t, "World", "on_entity_remove", "RemoveEntityFromInstance");

        // --- Server ---
        put(t, "Server", "on_list_ping", "ServerListPing");
        put(t, "Server", "on_client_ping", "ClientPingServer");
        put(t, "Server", "on_tick_monitor", "ServerTickMonitor");
        put(t, "Server", "on_pre_login", "AsyncPlayerPreLogin");
        put(t, "Server", "on_player_configuration", "AsyncPlayerConfiguration");
        put(t, "Server", "on_tps_change", "TpsChange");

        return Map.copyOf(t);
    }
}
