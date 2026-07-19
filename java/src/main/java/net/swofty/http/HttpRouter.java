package net.swofty.http;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import net.swofty.model.ApiHandlerModel;

/**
 * Path-param router for api declarations (design 6B): literal segments
 * must match exactly, {@code :name} segments capture. Longest literal
 * match wins (routes are tried in declaration order with literal
 * segments preferred over captures at each position; first match wins
 * after sorting by specificity).
 */
public final class HttpRouter {
    /** One registered route. */
    record Route(String method, String[] segments, ApiHandlerModel handler) {
        int literalCount() {
            int count = 0;
            for (String segment : segments) {
                if (!segment.startsWith(":")) {
                    count++;
                }
            }
            return count;
        }
    }

    /** A resolved route: the handler plus captured params. */
    public record Match(ApiHandlerModel handler, Map<String, Object> params) {
    }

    private final List<Route> routes = new ArrayList<>();

    public void register(ApiHandlerModel handler) {
        String method = handler.method() == null ? "any" : handler.method().toLowerCase();
        routes.add(new Route(method, split(handler.path()), handler));
        // more specific (more literal segments) first; stable within a tier
        routes.sort((a, b) -> Integer.compare(b.literalCount(), a.literalCount()));
    }

    public int size() {
        return routes.size();
    }

    private static String[] split(String path) {
        String trimmed = path.startsWith("/") ? path.substring(1) : path;
        if (trimmed.endsWith("/")) {
            trimmed = trimmed.substring(0, trimmed.length() - 1);
        }
        return trimmed.isEmpty() ? new String[0] : trimmed.split("/");
    }

    /**
     * Resolve a request; null when no route matches.
     */
    public Match match(String method, String path) {
        String[] segments = split(path);
        for (Route route : routes) {
            if (!route.method().equals("any")
                    && !route.method().equalsIgnoreCase(method)) {
                continue;
            }
            Map<String, Object> params = matchSegments(route.segments(), segments);
            if (params != null) {
                return new Match(route.handler(), params);
            }
        }
        return null;
    }

    private static Map<String, Object> matchSegments(String[] pattern, String[] actual) {
        if (pattern.length != actual.length) {
            return null;
        }
        Map<String, Object> params = new LinkedHashMap<>();
        for (int i = 0; i < pattern.length; i++) {
            if (pattern[i].startsWith(":")) {
                params.put(pattern[i].substring(1), decode(actual[i]));
            } else if (!pattern[i].equals(actual[i])) {
                return null;
            }
        }
        return params;
    }

    private static String decode(String segment) {
        return java.net.URLDecoder.decode(segment, java.nio.charset.StandardCharsets.UTF_8);
    }
}
