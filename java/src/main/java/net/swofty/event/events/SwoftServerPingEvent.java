package net.swofty.event.events;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.event.server.ServerListPingEvent;
import net.minestom.server.ping.Status;
import net.swofty.TextFormat;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.nativebridge.representation.Event;
import net.swofty.runtime.SystemSender;

/**
 * event ServerPing { motd rw, online rw, max rw } wrapper over
 * ServerListPingEvent (design 6D): dynamic MOTDs and fake counts write
 * straight into the ping's status response.
 */
public class SwoftServerPingEvent extends AbstractSwoftEvent<ServerListPingEvent> {
    public SwoftServerPingEvent(ServerListPingEvent minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
    }

    public String getMotd() {
        var description = minestomEvent.getStatus().description();
        return description != null ? TextFormat.plain(description) : "";
    }

    public void setMotd(String motd) {
        Status status = minestomEvent.getStatus();
        minestomEvent.setStatus(Status.builder(status)
                .description(TextFormat.component(motd))
                .build());
    }

    public int getOnline() {
        Status.PlayerInfo info = minestomEvent.getStatus().playerInfo();
        return info != null ? info.onlinePlayers() : 0;
    }

    public void setOnline(int online) {
        Status status = minestomEvent.getStatus();
        Status.PlayerInfo info = status.playerInfo();
        int max = info != null ? info.maxPlayers() : 0;
        minestomEvent.setStatus(Status.builder(status)
                .playerInfo(online, max)
                .build());
    }

    public int getMax() {
        Status.PlayerInfo info = minestomEvent.getStatus().playerInfo();
        return info != null ? info.maxPlayers() : 0;
    }

    public void setMax(int max) {
        Status status = minestomEvent.getStatus();
        Status.PlayerInfo info = status.playerInfo();
        int online = info != null ? info.onlinePlayers() : 0;
        minestomEvent.setStatus(Status.builder(status)
                .playerInfo(online, max)
                .build());
    }

    @Override
    public CommandSender getSender() {
        try {
            return MinecraftServer.getCommandManager().getConsoleSender();
        } catch (Throwable t) {
            return SystemSender.INSTANCE;
        }
    }
}
