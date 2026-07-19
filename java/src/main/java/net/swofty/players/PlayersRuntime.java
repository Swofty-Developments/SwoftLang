package net.swofty.players;

import net.minestom.server.MinecraftServer;
import net.minestom.server.event.GlobalEventHandler;
import net.minestom.server.event.player.PlayerDisconnectEvent;
import net.minestom.server.event.player.PlayerSpawnEvent;

/**
 * Live listeners feeding the seen-players store (phase 8): every join
 * (PlayerSpawn) refreshes the name and timestamps, every disconnect
 * stamps last_seen. Registered once from the engine register() pass.
 */
public final class PlayersRuntime {
    private static boolean initialized = false;

    private PlayersRuntime() {
    }

    public static synchronized void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        GlobalEventHandler handler = MinecraftServer.getGlobalEventHandler();
        handler.addListener(PlayerSpawnEvent.class, event ->
                SeenPlayersStore.recordJoin(event.getPlayer().getUuid(),
                        event.getPlayer().getUsername()));
        handler.addListener(PlayerDisconnectEvent.class, event ->
                SeenPlayersStore.recordQuit(event.getPlayer().getUuid(),
                        event.getPlayer().getUsername()));
    }
}
