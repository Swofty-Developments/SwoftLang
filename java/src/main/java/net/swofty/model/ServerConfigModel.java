package net.swofty.model;

import java.util.List;
import java.util.Map;

/**
 * server { ... } block: auth kind is mojang|velocity|bungeecord|offline
 * (secret only for velocity); at most one block across all scripts.
 * Phase-6 additions (design 6B/6D): http { port, bind } sub-block,
 * favicon path (base64'd at boot for the ping response), a permissions
 * map ("user" -&gt; [perm...], "*" for everyone), and open_to_lan.
 * Phase-8 addition: fishing { min_bite, max_bite } bite-window bounds in
 * ticks (defaults 5s/30s). Later addition: lighting toggles whether world
 * instances use LightingChunk (sky/block light computed) or plain chunks;
 * default on.
 */
public record ServerConfigModel(
        String authKind,
        String authSecret,
        String host,
        int port,
        String brand,
        String motd,
        String favicon,
        int httpPort,
        String httpBind,
        Map<String, List<String>> permissions,
        boolean openToLan,
        int fishingMinBiteTicks,
        int fishingMaxBiteTicks,
        boolean lighting) {

    /** Default fishing bite window: 5-30 seconds. */
    public static final int DEFAULT_FISHING_MIN_BITE_TICKS = 100;
    public static final int DEFAULT_FISHING_MAX_BITE_TICKS = 600;

    /** Lighting (LightingChunk) is on unless the server block opts out. */
    public static final boolean DEFAULT_LIGHTING = true;

    /** Pre-lighting shape, kept for existing call sites and tests. */
    public ServerConfigModel(String authKind, String authSecret, String host,
            int port, String brand, String motd, String favicon, int httpPort,
            String httpBind, Map<String, List<String>> permissions, boolean openToLan,
            int fishingMinBiteTicks, int fishingMaxBiteTicks) {
        this(authKind, authSecret, host, port, brand, motd, favicon, httpPort,
                httpBind, permissions, openToLan, fishingMinBiteTicks,
                fishingMaxBiteTicks, DEFAULT_LIGHTING);
    }

    /** Pre-phase-8 shape, kept for existing call sites and tests. */
    public ServerConfigModel(String authKind, String authSecret, String host,
            int port, String brand, String motd, String favicon, int httpPort,
            String httpBind, Map<String, List<String>> permissions, boolean openToLan) {
        this(authKind, authSecret, host, port, brand, motd, favicon, httpPort,
                httpBind, permissions, openToLan,
                DEFAULT_FISHING_MIN_BITE_TICKS, DEFAULT_FISHING_MAX_BITE_TICKS);
    }

    /** Pre-phase-6 shape, kept for existing call sites and tests. */
    public ServerConfigModel(String authKind, String authSecret, String host,
            int port, String brand, String motd) {
        this(authKind, authSecret, host, port, brand, motd,
                null, -1, "127.0.0.1", null, false);
    }

    public boolean hasHttp() {
        return httpPort > 0;
    }
}
