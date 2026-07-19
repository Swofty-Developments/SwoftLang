package net.swofty.players;

import java.util.UUID;

import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Player;
import net.swofty.props.NoneValue;
import net.swofty.props.PropertyDef;
import net.swofty.props.PropertyRegistry;

/**
 * OfflinePlayer property rows (phase 8). The rows registered for
 * OfflinePlayerValue serve pure-offline values; because the checker
 * composes OfflinePlayer rows onto Player (Player is a subtype), the
 * rows Player does not declare itself (player, first_seen, last_seen,
 * has_played_before) are ALSO registered for the live Player class,
 * delegating through the uuid — otherwise checker-green scripts touching
 * them on an event's player would die at runtime. The 'player' row is
 * THE bridge: on an offline value a live ConnectionManager lookup
 * yielding the online Player or none; on a live Player it is identity.
 */
public final class OfflinePlayerProperties {
    private static boolean registered = false;

    private OfflinePlayerProperties() {
    }

    public static synchronized void ensureRegistered() {
        if (registered) {
            return;
        }
        registered = true;

        PropertyRegistry.register(PropertyDef.readOnly("name", OfflinePlayerValue.class,
                OfflinePlayerValue::name));
        PropertyRegistry.register(PropertyDef.readOnly("uuid", OfflinePlayerValue.class,
                OfflinePlayerValue::uuid));
        PropertyRegistry.register(PropertyDef.readOnly("online", OfflinePlayerValue.class,
                offline -> onlinePlayer(offline) != null));
        PropertyRegistry.register(PropertyDef.readOnly("player", OfflinePlayerValue.class,
                offline -> {
                    Player player = onlinePlayer(offline);
                    return player != null ? player : NoneValue.INSTANCE;
                }));
        PropertyRegistry.register(PropertyDef.readOnly("first_seen", OfflinePlayerValue.class,
                offline -> {
                    String seen = SeenPlayersStore.firstSeen(offline.uuid());
                    return seen != null ? seen : "unknown";
                }));
        PropertyRegistry.register(PropertyDef.readOnly("last_seen", OfflinePlayerValue.class,
                offline -> {
                    // reading while the player is online means "seen now"
                    if (onlinePlayer(offline) != null) {
                        return SeenPlayersStore.isoNow();
                    }
                    String seen = SeenPlayersStore.lastSeen(offline.uuid());
                    return seen != null ? seen : "unknown";
                }));
        PropertyRegistry.register(PropertyDef.readOnly("has_played_before",
                OfflinePlayerValue.class,
                offline -> SeenPlayersStore.hasPlayedBefore(offline.uuid())));

        // The composed rows on live Player values (mirrors the checker's
        // offline_extra_props: every OfflinePlayer row Player does not
        // declare itself resolves on a Player-classed owner too).
        PropertyRegistry.register(PropertyDef.readOnly("player", Player.class,
                player -> player)); // the bridge is identity for an online Player
        PropertyRegistry.register(PropertyDef.readOnly("first_seen", Player.class,
                player -> {
                    String seen = SeenPlayersStore.firstSeen(player.getUuid().toString());
                    return seen != null ? seen : "unknown";
                }));
        PropertyRegistry.register(PropertyDef.readOnly("last_seen", Player.class,
                // a live player is being seen right now
                player -> SeenPlayersStore.isoNow()));
        PropertyRegistry.register(PropertyDef.readOnly("has_played_before", Player.class,
                player -> SeenPlayersStore.hasPlayedBefore(player.getUuid().toString())));
    }

    /** Live lookup, serverless-safe: null when offline or no server. */
    static Player onlinePlayer(OfflinePlayerValue offline) {
        try {
            return MinecraftServer.getConnectionManager()
                    .getOnlinePlayerByUuid(UUID.fromString(offline.uuid()));
        } catch (Throwable t) {
            return null;
        }
    }
}
