package net.swofty.persist.network;

import java.net.InetAddress;
import java.util.UUID;

/**
 * This process's identity on the network (design 1.10.0 §2/§5): the lease owner
 * token and the {@code origin_server} stamped into every broadcast so a server
 * can ignore its own echo.
 *
 * <p>Resolved once, in order: the {@code SWOFT_SERVER_ID} environment variable,
 * the {@code swoft.server.id} system property, else {@code <hostname>-<pid>-<rand>}.
 * The generated form is deliberately unique per PROCESS, not per host: two
 * servers on one box must never share a lease owner token, and a restarted
 * server must not be mistaken for its own crashed predecessor (whose lease then
 * expires by TTL instead of being silently re-adopted).
 */
public final class ServerIdentity {
    private static final String ID = resolve();

    private ServerIdentity() {
    }

    /** The stable id of this server process. */
    public static String id() {
        return ID;
    }

    private static String resolve() {
        String env = System.getenv("SWOFT_SERVER_ID");
        if (env != null && !env.isBlank()) {
            return env.trim();
        }
        String property = System.getProperty("swoft.server.id");
        if (property != null && !property.isBlank()) {
            return property.trim();
        }
        String host;
        try {
            host = InetAddress.getLocalHost().getHostName();
        } catch (Exception e) {
            host = "server";
        }
        return host + "-" + ProcessHandle.current().pid() + "-"
                + UUID.randomUUID().toString().substring(0, 8);
    }
}
