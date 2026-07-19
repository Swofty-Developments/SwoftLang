package net.swofty.motd;

import java.nio.file.Files;
import java.nio.file.Path;

import net.minestom.server.MinecraftServer;
import net.minestom.server.event.server.ServerListPingEvent;
import net.minestom.server.ping.Status;
import net.swofty.TextFormat;
import net.swofty.model.ServerConfigModel;

/**
 * MOTD + favicon over ServerListPingEvent (design 6D): the server{}
 * motd/favicon apply on every ping; setMotd (ServerValue.motd / the
 * set_motd statement) swaps the text at runtime. Script ServerPing
 * event handlers run AFTER this base listener (they are registered on
 * their own child node), so they can override anything.
 */
public final class MotdRuntime {
    private static volatile String motd;
    private static volatile byte[] faviconBytes;
    private static volatile boolean listening = false;

    private MotdRuntime() {
    }

    public static void init(ServerConfigModel config) {
        if (config != null && config.motd() != null) {
            motd = config.motd();
        }
        if (config != null && config.favicon() != null) {
            loadFavicon(config.favicon());
        }
        if (listening) {
            return;
        }
        try {
            MinecraftServer.getGlobalEventHandler().addListener(
                    ServerListPingEvent.class, MotdRuntime::applyTo);
            listening = true;
        } catch (Throwable t) {
            System.err.println("[motd] ping listener not registered (no server): " + t);
        }
    }

    private static void applyTo(ServerListPingEvent event) {
        String current = motd;
        byte[] favicon = faviconBytes;
        if (current == null && favicon == null) {
            return;
        }
        // Status is an immutable record now: rebuild from the event's current
        // status so anything already set (version info, player counts) survives.
        Status.Builder builder = Status.builder(event.getStatus());
        if (current != null) {
            builder.description(TextFormat.component(current));
        }
        if (favicon != null) {
            builder.favicon(favicon);
        }
        event.setStatus(builder.build());
    }

    /** Read the raw png bytes at boot (design 6D); Status.favicon is byte[]. */
    private static void loadFavicon(String path) {
        try {
            faviconBytes = Files.readAllBytes(Path.of(path));
        } catch (Exception e) {
            System.err.println("[motd] cannot read favicon '" + path + "': " + e.getMessage());
        }
    }

    public static String getMotd() {
        return motd != null ? motd : "";
    }

    public static void setMotd(String value) {
        motd = value;
    }
}
