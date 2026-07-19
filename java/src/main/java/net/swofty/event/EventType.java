package net.swofty.event;

import net.minestom.server.event.player.PlayerChatEvent;
import net.minestom.server.event.player.PlayerSpawnEvent;
import net.swofty.event.events.SwoftMobDamageEvent;
import net.swofty.event.events.SwoftMobDeathEvent;
import net.swofty.event.events.SwoftMobSpawnEvent;
import net.swofty.event.events.SwoftPlayerChatEvent;
import net.swofty.event.events.SwoftPlayerJoinEvent;
import net.swofty.event.events.SwoftPlayerUseItemEvent;
import net.swofty.items.event.PlayerUseCustomItemEvent;
import net.swofty.mobs.event.MobDamageEvent;
import net.swofty.mobs.event.MobDeathEvent;
import net.swofty.mobs.event.MobSpawnEvent;
import net.swofty.nativebridge.representation.Event;

/**
 * Registry of event types and their associated wrapper classes
 */
public enum EventType {
    // Define event types with their identifiers and wrapper class factories
    PLAYER_CHAT("PlayerChat", (minestomEvent, swoftEvent) ->
        new SwoftPlayerChatEvent((PlayerChatEvent) minestomEvent, swoftEvent)),

    PLAYER_JOIN("PlayerJoin", (minestomEvent, swoftEvent) ->
        new SwoftPlayerJoinEvent((PlayerSpawnEvent) minestomEvent, swoftEvent)),

    // Phase-5 content events (design 5A/5B): custom Minestom events fired by
    // the item/mob runtimes via EventDispatcher
    PLAYER_USE_ITEM("PlayerUseItem", (minestomEvent, swoftEvent) ->
        new SwoftPlayerUseItemEvent((PlayerUseCustomItemEvent) minestomEvent, swoftEvent)),

    MOB_SPAWN("MobSpawn", (minestomEvent, swoftEvent) ->
        new SwoftMobSpawnEvent((MobSpawnEvent) minestomEvent, swoftEvent)),

    MOB_DEATH("MobDeath", (minestomEvent, swoftEvent) ->
        new SwoftMobDeathEvent((MobDeathEvent) minestomEvent, swoftEvent)),

    MOB_DAMAGE("MobDamage", (minestomEvent, swoftEvent) ->
        new SwoftMobDamageEvent((MobDamageEvent) minestomEvent, swoftEvent)),

    // Phase-6 platform events (design 6B/6D)
    TPS_CHANGE("TpsChange", (minestomEvent, swoftEvent) ->
        new net.swofty.event.events.SwoftTpsChangeEvent(
                (net.swofty.tps.TpsChangeEvent) minestomEvent, swoftEvent)),

    BLOCK_BREAK("BlockBreak", (minestomEvent, swoftEvent) ->
        new net.swofty.event.events.SwoftBlockBreakEvent(
                (net.minestom.server.event.player.PlayerBlockBreakEvent) minestomEvent,
                swoftEvent)),

    BLOCK_PLACE("BlockPlace", (minestomEvent, swoftEvent) ->
        new net.swofty.event.events.SwoftBlockPlaceEvent(
                (net.minestom.server.event.player.PlayerBlockPlaceEvent) minestomEvent,
                swoftEvent)),

    SERVER_PING("ServerPing", (minestomEvent, swoftEvent) ->
        new net.swofty.event.events.SwoftServerPingEvent(
                (net.minestom.server.event.server.ServerListPingEvent) minestomEvent,
                swoftEvent)),

    // Phase-8 fishing events (native fishing engine)
    PLAYER_CAST_ROD("PlayerCastRod", (minestomEvent, swoftEvent) ->
        new net.swofty.event.events.SwoftPlayerCastRodEvent(
                (net.swofty.fishing.event.PlayerCastRodEvent) minestomEvent, swoftEvent)),

    FISH_BITE("FishBite", (minestomEvent, swoftEvent) ->
        new net.swofty.event.events.SwoftFishBiteEvent(
                (net.swofty.fishing.event.FishBiteEvent) minestomEvent, swoftEvent)),

    PLAYER_CATCH_FISH("PlayerCatchFish", (minestomEvent, swoftEvent) ->
        new net.swofty.event.events.SwoftPlayerCatchFishEvent(
                (net.swofty.fishing.event.PlayerCatchFishEvent) minestomEvent, swoftEvent)),

    PLAYER_REEL_IN("PlayerReelIn", (minestomEvent, swoftEvent) ->
        new net.swofty.event.events.SwoftPlayerReelInEvent(
                (net.swofty.fishing.event.PlayerReelInEvent) minestomEvent, swoftEvent)),

    // Phase-9 dispenser runtime (net.swofty.blocks)
    BLOCK_DISPENSE("BlockDispense", (minestomEvent, swoftEvent) ->
        new net.swofty.event.events.SwoftBlockDispenseEvent(
                (net.swofty.blocks.event.BlockDispenseEvent) minestomEvent, swoftEvent)),

    // Phase-10 command preprocess veto (fires pre-dispatch on the command path)
    PLAYER_COMMAND("PlayerCommand", (minestomEvent, swoftEvent) ->
        new net.swofty.event.events.SwoftPlayerCommandEvent(
                (net.minestom.server.event.player.PlayerCommandEvent) minestomEvent,
                swoftEvent)),

        ;
    
    // Add more event types as needed
    
    private final String identifier;
    private final EventWrapperFactory factory;
    
    /**
     * Map from identifier to matching Minestom class name
     */
    private static final java.util.Map<String, String> MINESTOM_CLASS_MAP = new java.util.HashMap<>();
    
    static {
        // Initialize the mapping from identifiers to Minestom class names
        MINESTOM_CLASS_MAP.put("PlayerChat", "net.minestom.server.event.player.PlayerChatEvent");
        MINESTOM_CLASS_MAP.put("PlayerJoin", "net.minestom.server.event.player.PlayerSpawnEvent");
        MINESTOM_CLASS_MAP.put("PlayerMove", "net.minestom.server.event.player.PlayerMoveEvent");
        MINESTOM_CLASS_MAP.put("PlayerUseItem", "net.swofty.items.event.PlayerUseCustomItemEvent");
        MINESTOM_CLASS_MAP.put("MobSpawn", "net.swofty.mobs.event.MobSpawnEvent");
        MINESTOM_CLASS_MAP.put("MobDeath", "net.swofty.mobs.event.MobDeathEvent");
        MINESTOM_CLASS_MAP.put("MobDamage", "net.swofty.mobs.event.MobDamageEvent");
        // Phase-6 platform events (design 6B/6D)
        MINESTOM_CLASS_MAP.put("TpsChange", "net.swofty.tps.TpsChangeEvent");
        MINESTOM_CLASS_MAP.put("BlockBreak",
                "net.minestom.server.event.player.PlayerBlockBreakEvent");
        MINESTOM_CLASS_MAP.put("BlockPlace",
                "net.minestom.server.event.player.PlayerBlockPlaceEvent");
        MINESTOM_CLASS_MAP.put("ServerPing",
                "net.minestom.server.event.server.ServerListPingEvent");
        // Phase-8 fishing events (native fishing engine)
        MINESTOM_CLASS_MAP.put("PlayerCastRod",
                "net.swofty.fishing.event.PlayerCastRodEvent");
        MINESTOM_CLASS_MAP.put("FishBite",
                "net.swofty.fishing.event.FishBiteEvent");
        MINESTOM_CLASS_MAP.put("PlayerCatchFish",
                "net.swofty.fishing.event.PlayerCatchFishEvent");
        MINESTOM_CLASS_MAP.put("PlayerReelIn",
                "net.swofty.fishing.event.PlayerReelInEvent");
        // Phase-9 dispenser runtime
        MINESTOM_CLASS_MAP.put("BlockDispense",
                "net.swofty.blocks.event.BlockDispenseEvent");
        // Phase-10 command preprocess veto
        MINESTOM_CLASS_MAP.put("PlayerCommand",
                "net.minestom.server.event.player.PlayerCommandEvent");
        // Add more mappings as needed
    }
    
    EventType(String identifier, EventWrapperFactory factory) {
        this.identifier = identifier;
        this.factory = factory;
    }
    
    public String getIdentifier() {
        return identifier;
    }
    
    public EventWrapperFactory getFactory() {
        return factory;
    }
    
    /**
     * Get the corresponding Minestom class name for an event identifier
     */
    public static String getMinestomClassName(String identifier) {
        return MINESTOM_CLASS_MAP.getOrDefault(identifier, 
            // Default fallback - try to infer based on identifier
            identifier.startsWith("Player") ? 
                "net.minestom.server.event.player." + identifier + "Event" :
                identifier.startsWith("Entity") ? 
                    "net.minestom.server.event.entity." + identifier + "Event" :
                    "net.minestom.server.event." + identifier + "Event");
    }
    
    /**
     * Find an event type by its identifier
     */
    public static EventType fromIdentifier(String identifier) {
        for (EventType type : values()) {
            if (type.getIdentifier().equals(identifier)) {
                return type;
            }
        }
        return null;
    }
    
    /**
     * Functional interface for event wrapper factories
     */
    @FunctionalInterface
    public interface EventWrapperFactory {
        AbstractSwoftEvent<?> create(net.minestom.server.event.Event minestomEvent, Event swoftEvent);
    }
}