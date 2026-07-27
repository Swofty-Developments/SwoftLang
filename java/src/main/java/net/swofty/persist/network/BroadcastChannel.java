package net.swofty.persist.network;

import java.util.function.Consumer;

/**
 * The change bus for replicated globals (design 1.10.0 §2.2 / §6): "pub-sub over
 * the coordinator/backend".
 *
 * <p>{@link RedisBroadcastChannel} is the real thing when a {@code coordinator:}
 * is configured; {@link BackendBusChannel} is the fallback that polls a reserved
 * row table in the shared backend, so a network deployment works with nothing
 * but mysql/mongodb — at poll latency instead of push latency.
 *
 * <p>Delivery is at-most-once and best-effort by design: the backend is the
 * authority (every atomic write is applied there before it is published), so a
 * dropped broadcast costs freshness on one replica, never correctness of the
 * stored value.
 */
public interface BroadcastChannel {

    /** Publish a message to every other server. Must not throw. */
    void publish(NetMessage message);

    /**
     * Start delivering messages to {@code handler}. Messages this server
     * originated are filtered out before the handler sees them (§5.4 self-echo
     * suppression).
     */
    void subscribe(Consumer<NetMessage> handler);

    /** Stop delivery and release the connection/poller. Idempotent. */
    void close();
}
