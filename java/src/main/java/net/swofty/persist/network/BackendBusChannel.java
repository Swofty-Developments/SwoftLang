package net.swofty.persist.network;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Consumer;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

import net.swofty.persist.SwoftStorage;

/**
 * The no-coordinator change bus (design 1.10.0 §2.2 / §6: "backend polling/
 * notify fallback"). Messages are rows in a reserved persistent variable; every
 * server polls them and applies the ones it did not originate.
 *
 * <p>Bounded by construction: each server writes into its own ring of
 * {@link #RING_SLOTS} row keys ({@code <origin>#<n mod slots>}), so the table
 * size is (servers x slots) forever — no growth, no sweeper, no delete
 * primitive needed from {@link SwoftStorage}. Each message carries its sequence
 * number and a receiver only applies sequences ahead of the last it saw from
 * that origin, so a wrapped-over slot cannot replay an old message.
 *
 * <p>{@link #subscribe} takes the high-water marks synchronously before the
 * poller starts, and dispatches nothing on that pass: replaying the bus history
 * at startup would re-apply changes the boot-time replica load already contains.
 * Doing it synchronously (rather than on the first timed poll) is what makes the
 * boundary exact — otherwise a whole poll interval of other servers' messages
 * would fall into the gap and be discarded as history.
 */
public final class BackendBusChannel implements BroadcastChannel {

    /** Reserved variable holding the message ring. */
    public static final String RESERVED_VAR = "__swoft_bus";

    /** Ring slots per origin server. */
    public static final int RING_SLOTS = 64;

    /** How often the poller sweeps the table. */
    public static final long POLL_MILLIS = 250L;

    private final SwoftStorage storage;
    private final String origin;
    private final AtomicLong sequence = new AtomicLong();
    private final Map<String, Long> lastSeen = new HashMap<>();

    private volatile boolean running = true;
    private volatile boolean primed;
    private Thread poller;

    public BackendBusChannel(SwoftStorage storage, String origin) {
        this.storage = storage;
        this.origin = origin;
    }

    @Override
    public void publish(NetMessage message) {
        long seq = sequence.incrementAndGet();
        JsonObject row = new JsonObject();
        row.addProperty("seq", seq);
        row.addProperty("payload", message.toJson());
        try {
            storage.writeBatch(RESERVED_VAR,
                    Map.of(origin + "#" + (seq % RING_SLOTS), row));
        } catch (Exception e) {
            System.err.println("[persist] bus publish failed for '" + message.var()
                    + "': " + e.getMessage()
                    + " - other servers stay stale until their next load");
        }
    }

    @Override
    public void subscribe(Consumer<NetMessage> handler) {
        // Prime SYNCHRONOUSLY, before the poller exists and before this server can
        // publish anything. Priming lazily on the first poll instead would put a
        // whole poll interval between boot and the water marks being taken, and
        // every message another server published inside that window would be
        // swallowed as "history" - the first broadcast after startup would be
        // lost exactly when replicas are least likely to agree already.
        try {
            poll(handler);
        } catch (Exception e) {
            System.err.println("[persist] priming the bus failed: " + e.getMessage()
                    + " - the first poll will prime instead");
        }
        poller = Thread.ofVirtual().name("swoft-persist-bus-poll").start(() -> {
            while (running) {
                try {
                    Thread.sleep(POLL_MILLIS);
                } catch (InterruptedException e) {
                    return;
                }
                if (!running) {
                    return;
                }
                try {
                    poll(handler);
                } catch (Exception e) {
                    System.err.println("[persist] bus poll failed: " + e.getMessage());
                }
            }
        });
    }

    private void poll(Consumer<NetMessage> handler) {
        Map<String, JsonElement> rows = storage.loadAll(RESERVED_VAR);
        boolean priming = !primed;
        for (Map.Entry<String, JsonElement> entry : rows.entrySet()) {
            String slot = entry.getKey();
            int hash = slot.lastIndexOf('#');
            String rowOrigin = hash > 0 ? slot.substring(0, hash) : slot;
            if (origin.equals(rowOrigin)) {
                // §5.4 self-echo suppression
                continue;
            }
            JsonElement element = entry.getValue();
            if (element == null || !element.isJsonObject()) {
                continue;
            }
            JsonObject row = element.getAsJsonObject();
            if (!row.has("seq") || !row.has("payload")) {
                continue;
            }
            long seq = row.get("seq").getAsLong();
            Long seen = lastSeen.get(slot);
            if (seen != null && seq <= seen) {
                continue;
            }
            lastSeen.put(slot, seq);
            if (priming) {
                // boot: record the water mark, do not replay history
                continue;
            }
            NetMessage message = NetMessage.fromJson(row.get("payload").getAsString());
            if (message == null || origin.equals(message.origin())) {
                continue;
            }
            try {
                handler.accept(message);
            } catch (Exception e) {
                System.err.println("[persist] applying a bus message for '" + message.var()
                        + "' failed: " + e.getMessage());
            }
        }
        primed = true;
    }

    @Override
    public void close() {
        running = false;
        if (poller != null) {
            poller.interrupt();
        }
    }
}
