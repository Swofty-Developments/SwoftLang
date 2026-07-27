package net.swofty.persist.change;

import java.util.ArrayList;
import java.util.List;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

/**
 * The propagating causality token of design 1.10.0 §5.3:
 * {@code {chain_id, origin_server, depth}} plus the chain path used for the
 * rejection message.
 *
 * <p><b>Why it travels on the wire.</b> A per-server depth counter does not stop
 * a network cascade: A writes at depth 1, broadcasts, B sees a "fresh" change at
 * depth 0, writes, broadcasts, A sees depth 0 — forever. So the token is
 * serialized into every broadcast ({@link #toJson()} /
 * {@link #fromJson(JsonElement)}) and the receiving server continues the SAME
 * chain, which is what makes an A -&gt; B -&gt; A ping-pong accumulate depth
 * until the cap trips.
 *
 * <p>{@link #originServer()} is the server the CHAIN started on, which is not
 * the same thing as the {@code origin} of a bus message (the server that
 * published that particular message, used for §5.4 self-echo suppression) —
 * a handler on B writing inside a chain A started publishes with origin B and
 * chain origin A.
 */
public record CausalityToken(String chain, String originServer, int depth, List<String> path) {

    /** One step of the chain, e.g. {@code coins(Steve)}. */
    public static String step(String var, String key) {
        return key == null || key.isEmpty() ? var : var + '(' + key + ')';
    }

    /** This token continued by one more write, one level deeper. */
    public CausalityToken deeper(String var, String key) {
        List<String> next = new ArrayList<>(path.size() + 1);
        next.addAll(path);
        next.add(step(var, key));
        return new CausalityToken(chain, originServer, depth + 1, List.copyOf(next));
    }

    /** The chain path as {@code a -> b -> c}, tail-trimmed when very long. */
    public String describePath() {
        int from = Math.max(0, path.size() - 12);
        StringBuilder out = new StringBuilder();
        if (from > 0) {
            out.append("... -> ");
        }
        for (int i = from; i < path.size(); i++) {
            if (i > from) {
                out.append(" -> ");
            }
            out.append(path.get(i));
        }
        return out.toString();
    }

    public JsonObject toJson() {
        JsonObject object = new JsonObject();
        object.addProperty("chain", chain);
        object.addProperty("origin", originServer);
        object.addProperty("depth", depth);
        JsonArray steps = new JsonArray();
        for (String entry : path) {
            steps.add(entry);
        }
        object.add("path", steps);
        return object;
    }

    /** Parse a token off a bus message; null when the message carries none. */
    public static CausalityToken fromJson(JsonElement element) {
        if (element == null || !element.isJsonObject()) {
            return null;
        }
        try {
            JsonObject object = element.getAsJsonObject();
            List<String> steps = new ArrayList<>();
            if (object.has("path") && object.get("path").isJsonArray()) {
                for (JsonElement entry : object.getAsJsonArray("path")) {
                    steps.add(entry.getAsString());
                }
            }
            return new CausalityToken(
                    object.has("chain") ? object.get("chain").getAsString() : "?",
                    object.has("origin") ? object.get("origin").getAsString() : "?",
                    object.has("depth") ? object.get("depth").getAsInt() : 0,
                    List.copyOf(steps));
        } catch (Exception e) {
            return null;
        }
    }
}
