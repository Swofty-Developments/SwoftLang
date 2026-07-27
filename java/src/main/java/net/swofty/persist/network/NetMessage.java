package net.swofty.persist.network;

import com.google.gson.JsonElement;
import com.google.gson.JsonNull;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

/**
 * One broadcast on the persistence bus (design 1.10.0 §2.2).
 *
 * <p>{@code origin} is the {@code origin_server} of §5.4 self-echo suppression:
 * the writer already applied the change to its own state before publishing, so
 * it drops the echo of its own message instead of applying it twice.
 *
 * <p>Two kinds:
 * <ul>
 *   <li>{@link #KIND_VALUE} — a whole-row snapshot of a replicated global after
 *       an atomic op was applied at the backend. {@code version} is the
 *       monotonic stamp of the row afterwards; a replica refuses a message whose
 *       version is behind what it already holds, so a duplicated or reordered
 *       delivery cannot roll a value backwards.</li>
 *   <li>{@link #KIND_OP} — an atomic op aimed at a session-owned row whose owner
 *       is another server ("routed to owner", §3.2). Only the server holding
 *       that subject's lease applies it, to its live in-memory copy; every other
 *       server ignores it. {@code value} carries the operand and {@code entry}
 *       the map key for {@code set X at K to V}.</li>
 * </ul>
 *
 * <p>The wire form is a small JSON object, so redis pub-sub and the
 * backend-polled bus carry exactly the same payload.
 */
public record NetMessage(String kind, String var, String key, JsonElement value,
        String origin, long version, String op, JsonElement entry) {

    /** A whole-row snapshot after an atomic op was applied at the backend. */
    public static final String KIND_VALUE = "value";

    /** An atomic op routed to whichever server owns the subject's session. */
    public static final String KIND_OP = "op";

    public static NetMessage value(String var, String key, JsonElement value,
            String origin, long version) {
        return new NetMessage(KIND_VALUE, var, key, value, origin, version, null, null);
    }

    public static NetMessage op(String var, String key, AtomicOp op, JsonElement operand,
            JsonElement entry, String origin) {
        return new NetMessage(KIND_OP, var, key, operand, origin, 0L, op.name(), entry);
    }

    /** The atomic op of a {@link #KIND_OP} message, or null. */
    public AtomicOp atomicOp() {
        return AtomicOp.parse(op);
    }

    public String toJson() {
        JsonObject object = new JsonObject();
        object.addProperty("kind", kind);
        object.addProperty("var", var);
        object.addProperty("key", key);
        object.add("value", value == null ? JsonNull.INSTANCE : value);
        object.addProperty("origin", origin);
        object.addProperty("version", version);
        if (op != null) {
            object.addProperty("op", op);
        }
        if (entry != null) {
            object.add("entry", entry);
        }
        return object.toString();
    }

    /** Parse a bus payload; null when it is not a well-formed message. */
    public static NetMessage fromJson(String payload) {
        try {
            JsonElement parsed = JsonParser.parseString(payload);
            if (!parsed.isJsonObject()) {
                return null;
            }
            JsonObject object = parsed.getAsJsonObject();
            if (!object.has("var") || !object.has("origin")) {
                return null;
            }
            return new NetMessage(
                    object.has("kind") ? object.get("kind").getAsString() : KIND_VALUE,
                    object.get("var").getAsString(),
                    object.has("key") ? object.get("key").getAsString() : "",
                    object.get("value"),
                    object.get("origin").getAsString(),
                    object.has("version") ? object.get("version").getAsLong() : 0L,
                    object.has("op") && !object.get("op").isJsonNull()
                            ? object.get("op").getAsString() : null,
                    object.get("entry"));
        } catch (Exception e) {
            System.err.println("[persist] dropping malformed bus message: " + e.getMessage());
            return null;
        }
    }
}
