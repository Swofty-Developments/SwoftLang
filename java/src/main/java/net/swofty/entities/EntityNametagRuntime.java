package net.swofty.entities;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.TextDecoration;
import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.Metadata;
import net.minestom.server.entity.MetadataDef;
import net.minestom.server.entity.Player;
import net.minestom.server.event.player.PlayerDisconnectEvent;
import net.minestom.server.network.packet.server.play.EntityMetaDataPacket;
import net.swofty.TextFormat;
import net.swofty.items.ItemLoreBuilder;

/**
 * Per-viewer overhead entity names (W-viewers, feature 3):
 * {@code set name of <entity> to <String> for <player>} shows a different
 * overhead name to a single viewer without touching what everyone else sees.
 *
 * <p>Implementation: a per-viewer {@link EntityMetaDataPacket} carrying just the
 * two custom-name metadata rows. The indices are read live from the pinned jar
 * ({@link MetadataDef#CUSTOM_NAME} and {@link MetadataDef#CUSTOM_NAME_VISIBLE},
 * javap-verified against 26.2 as metadata indices 2 and 3) rather than
 * hardcoded, and the values are built with {@link Metadata#OptComponent} /
 * {@link Metadata#Boolean}. The packet is sent to that one connection, so the
 * client renders the override for this entity while every other viewer keeps the
 * entity's real {@link Entity#getCustomName()}.
 *
 * <p>Overrides are tracked per (entity id, viewer uuid). They are re-applied
 * when the entity is re-shown to the viewer (a fresh spawn resets client
 * metadata — {@link ViewerControl#show}), and dropped on hide, on the viewer's
 * disconnect, and on hot-reload {@link #teardown()}. Clearing an override
 * re-pushes the entity's real custom name to that viewer so the world snaps back
 * to the shared name.
 */
public final class EntityNametagRuntime {
    /** entity id -> (viewer uuid -> MiniMessage/ampersand name source). */
    private static final Map<Integer, Map<UUID, String>> OVERRIDES = new ConcurrentHashMap<>();

    private static volatile boolean initialized = false;

    private EntityNametagRuntime() {
    }

    public static synchronized void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        MinecraftServer.getGlobalEventHandler().addListener(PlayerDisconnectEvent.class,
                event -> disconnect(event.getPlayer()));
    }

    /** {@code set name of <entity> to <name> for <viewer>}. */
    public static void set(Entity entity, String name, Player viewer) {
        OVERRIDES.computeIfAbsent(entity.getEntityId(), id -> new ConcurrentHashMap<>())
                .put(viewer.getUuid(), name);
        viewer.sendPacket(namePacket(entity, name));
    }

    /**
     * Re-push {@code viewer}'s override for {@code entity} (if any) after a
     * fresh spawn reset the client's metadata. Called from
     * {@link ViewerControl#show}.
     */
    public static void reapply(Entity entity, Player viewer) {
        Map<UUID, String> byViewer = OVERRIDES.get(entity.getEntityId());
        if (byViewer == null) {
            return;
        }
        String name = byViewer.get(viewer.getUuid());
        if (name != null) {
            viewer.sendPacket(namePacket(entity, name));
        }
    }

    /**
     * Drop {@code viewer}'s override because the entity was hidden from them.
     * The entity is no longer a viewer, so no reset packet is sent (the client
     * has already destroyed it); the tracking is simply released.
     */
    public static void clearHidden(Entity entity, Player viewer) {
        Map<UUID, String> byViewer = OVERRIDES.get(entity.getEntityId());
        if (byViewer != null) {
            byViewer.remove(viewer.getUuid());
            if (byViewer.isEmpty()) {
                OVERRIDES.remove(entity.getEntityId());
            }
        }
    }

    /**
     * Drop {@code viewer}'s override on an entity that stays visible, snapping
     * the overhead name back to the entity's shared {@link Entity#getCustomName()}
     * for that one viewer.
     */
    public static void reset(Entity entity, Player viewer) {
        clearHidden(entity, viewer);
        if (viewer.isOnline()) {
            viewer.sendPacket(resetPacket(entity));
        }
    }

    /** Forget every override on a removed/despawned entity. */
    public static void forget(Entity entity) {
        OVERRIDES.remove(entity.getEntityId());
    }

    private static void disconnect(Player player) {
        UUID id = player.getUuid();
        for (Map<UUID, String> byViewer : OVERRIDES.values()) {
            byViewer.remove(id);
        }
    }

    /** Hot-reload teardown (#58): forget every tracked per-viewer name. */
    public static void teardown() {
        OVERRIDES.clear();
    }

    /** Number of viewers holding a name override on an entity (harness hook). */
    public static int overrideCount(Entity entity) {
        Map<UUID, String> byViewer = OVERRIDES.get(entity.getEntityId());
        return byViewer == null ? 0 : byViewer.size();
    }

    private static EntityMetaDataPacket namePacket(Entity entity, String name) {
        Map<Integer, Metadata.Entry<?>> entries = new HashMap<>();
        entries.put(MetadataDef.CUSTOM_NAME.index(), Metadata.OptComponent(component(name)));
        entries.put(MetadataDef.CUSTOM_NAME_VISIBLE.index(), Metadata.Boolean(true));
        return new EntityMetaDataPacket(entity.getEntityId(), entries);
    }

    private static EntityMetaDataPacket resetPacket(Entity entity) {
        Map<Integer, Metadata.Entry<?>> entries = new HashMap<>();
        entries.put(MetadataDef.CUSTOM_NAME.index(), Metadata.OptComponent(entity.getCustomName()));
        entries.put(MetadataDef.CUSTOM_NAME_VISIBLE.index(),
                Metadata.Boolean(entity.isCustomNameVisible()));
        return new EntityMetaDataPacket(entity.getEntityId(), entries);
    }

    private static Component component(String text) {
        if (text == null || text.isEmpty()) {
            return Component.empty();
        }
        Component base = ItemLoreBuilder.isMiniMessage(text)
                ? TextFormat.component(text)
                : Component.text(text.replace("&", "§"));
        return base.decoration(TextDecoration.ITALIC, false);
    }
}
