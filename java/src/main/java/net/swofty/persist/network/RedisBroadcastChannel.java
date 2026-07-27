package net.swofty.persist.network;

import java.io.IOException;
import java.util.List;
import java.util.function.Consumer;

/**
 * Pub-sub change bus over a redis coordinator (design 1.10.0 §2.2).
 *
 * <p>Two connections, because a subscribed redis connection may not issue
 * ordinary commands: one for {@code PUBLISH}, one parked in {@code SUBSCRIBE}
 * on a virtual thread. The subscriber reconnects with a backoff if the socket
 * drops, and a reconnect re-subscribes — a coordinator restart degrades to a
 * few seconds of stale replicas, not a permanently deaf server.
 */
public final class RedisBroadcastChannel implements BroadcastChannel {

    /** Channel every server publishes replicated-global changes on. */
    public static final String CHANNEL = "swoft:persist:changes";

    private static final long RECONNECT_BACKOFF_MILLIS = 2_000L;

    private final String uri;
    private final String origin;
    private final RedisConnection publisher;

    private volatile boolean running = true;
    private volatile RedisConnection subscriber;
    private Thread listener;

    public RedisBroadcastChannel(String uri, String origin, RedisConnection publisher) {
        this.uri = uri;
        this.origin = origin;
        this.publisher = publisher;
    }

    @Override
    public void publish(NetMessage message) {
        try {
            publisher.command("PUBLISH", CHANNEL, message.toJson());
        } catch (IOException first) {
            try {
                publisher.reconnect();
                publisher.command("PUBLISH", CHANNEL, message.toJson());
            } catch (IOException e) {
                // the value is already durable at the backend; other servers
                // pick it up on their next boot/read. Loud, never silent.
                System.err.println("[persist] broadcast publish failed for '"
                        + message.var() + "': " + e.getMessage()
                        + " - other servers stay stale until their next load");
            }
        }
    }

    @Override
    public void subscribe(Consumer<NetMessage> handler) {
        listener = Thread.ofVirtual().name("swoft-persist-subscribe").start(() -> {
            while (running) {
                try (RedisConnection connection = RedisConnection.open(uri, 0)) {
                    subscriber = connection;
                    connection.send("SUBSCRIBE", CHANNEL);
                    while (running) {
                        Object reply = connection.readReply();
                        NetMessage message = decode(reply);
                        if (message == null || origin.equals(message.origin())) {
                            // §5.4: our own echo - already applied locally
                            continue;
                        }
                        try {
                            handler.accept(message);
                        } catch (Exception e) {
                            System.err.println("[persist] applying a broadcast for '"
                                    + message.var() + "' failed: " + e.getMessage());
                        }
                    }
                } catch (Exception e) {
                    if (!running) {
                        return;
                    }
                    System.err.println("[persist] change-bus subscription dropped ("
                            + e.getMessage() + ") - reconnecting");
                    try {
                        Thread.sleep(RECONNECT_BACKOFF_MILLIS);
                    } catch (InterruptedException interrupted) {
                        Thread.currentThread().interrupt();
                        return;
                    }
                }
            }
        });
    }

    /** A pub-sub delivery is ["message", channel, payload]. */
    private static NetMessage decode(Object reply) {
        if (!(reply instanceof List<?> parts) || parts.size() < 3) {
            return null;
        }
        if (!"message".equals(String.valueOf(parts.get(0)))) {
            return null;
        }
        Object payload = parts.get(2);
        return payload == null ? null : NetMessage.fromJson(String.valueOf(payload));
    }

    @Override
    public void close() {
        running = false;
        RedisConnection current = subscriber;
        if (current != null) {
            // closing the socket unblocks the parked readReply
            current.close();
        }
        if (listener != null) {
            listener.interrupt();
        }
        publisher.close();
    }
}
