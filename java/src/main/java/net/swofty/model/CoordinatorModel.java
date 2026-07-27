package net.swofty.model;

/**
 * storage { coordinator: redis "redis://host:port" } (design 1.10.0 §1): the
 * OPTIONAL lease store + pub-sub bus for {@code mode: network}. When absent the
 * runtime falls back to a lease table and a polled message bus inside the
 * configured backend, so a coordinator is a performance/latency upgrade rather
 * than a requirement.
 */
public record CoordinatorModel(String kind, String uri) {

    public static CoordinatorModel redis(String uri) {
        return new CoordinatorModel("redis", uri);
    }
}
