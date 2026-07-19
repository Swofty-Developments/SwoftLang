package net.swofty.players;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import net.swofty.ScriptError;
import net.swofty.async.AsyncRuntime;

/**
 * fetch_offline_player(name) (phase 8): ASYNC-ONLY builtin resolving a
 * username to its Mojang uuid over java.net.http ON the calling virtual
 * thread, with a 5s budget. Failures and timeouts resolve to none, never
 * an exception; successes seed the seen-players store so later
 * offline_player(name) lookups are instant.
 */
public final class MojangNameResolver {
    private static final Duration TIMEOUT = Duration.ofSeconds(5);
    private static final HttpClient CLIENT = HttpClient.newBuilder()
            .connectTimeout(TIMEOUT)
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build();

    private MojangNameResolver() {
    }

    /**
     * @return the resolved identity, or null (none) when the name is
     *         unknown or the Mojang API cannot be reached within budget
     */
    public static OfflinePlayerValue fetch(String username) {
        if (!AsyncRuntime.inTask()) {
            throw new ScriptError("fetch_offline_player() blocks on the Mojang API and is "
                    + "async-only; call it from an async context (async command/event, "
                    + "spawn, async {})");
        }
        try {
            HttpRequest request = HttpRequest.newBuilder(URI.create(
                            "https://api.mojang.com/users/profiles/minecraft/" + username))
                    .timeout(TIMEOUT)
                    .header("Accept", "application/json")
                    .GET()
                    .build();
            HttpResponse<String> response =
                    CLIENT.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200 || response.body() == null
                    || response.body().isBlank()) {
                return null;
            }
            JsonObject profile = JsonParser.parseString(response.body()).getAsJsonObject();
            JsonElement id = profile.get("id");
            if (id == null || id.isJsonNull()) {
                return null;
            }
            String name = profile.has("name") && !profile.get("name").isJsonNull()
                    ? profile.get("name").getAsString() : username;
            String uuid = dashed(id.getAsString());
            if (uuid == null) {
                return null;
            }
            SeenPlayersStore.seed(uuid, name);
            return new OfflinePlayerValue(uuid, name);
        } catch (Exception e) {
            return null;
        }
    }

    /** Mojang returns the undashed 32-hex form; canonicalize it. */
    static String dashed(String undashed) {
        if (undashed == null || !undashed.matches("[0-9a-fA-F]{32}")) {
            return null;
        }
        String lower = undashed.toLowerCase();
        return lower.substring(0, 8) + "-" + lower.substring(8, 12) + "-"
                + lower.substring(12, 16) + "-" + lower.substring(16, 20) + "-"
                + lower.substring(20);
    }
}
