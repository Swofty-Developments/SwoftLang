package net.swofty.skins;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import net.minestom.server.entity.PlayerSkin;
import net.swofty.ScriptError;
import net.swofty.async.AsyncRuntime;

/**
 * fetch_skin(username) (design 6D): ASYNC-ONLY builtin hitting the
 * Mojang API over java.net.http ON the calling virtual thread; a 5s
 * budget covers both requests (username -&gt; uuid -&gt; signed profile).
 * Failures and timeouts resolve to none, never an exception.
 */
public final class SkinFetcher {
    private static final Duration TIMEOUT = Duration.ofSeconds(5);
    private static final HttpClient CLIENT = HttpClient.newBuilder()
            .connectTimeout(TIMEOUT)
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build();

    private SkinFetcher() {
    }

    /**
     * @return the PlayerSkin, or null (none) when the name is unknown or
     *         the Mojang API cannot be reached within the budget
     */
    public static PlayerSkin fetch(String username) {
        if (!AsyncRuntime.inTask()) {
            throw new ScriptError("fetch_skin() blocks on the Mojang API and is async-only; "
                    + "call it from an async context (async command/event, spawn, async {})");
        }
        long deadline = System.nanoTime() + TIMEOUT.toNanos();
        try {
            String profile = get("https://api.mojang.com/users/profiles/minecraft/"
                    + username, deadline);
            if (profile == null || profile.isBlank()) {
                return null;
            }
            JsonObject profileObj = JsonParser.parseString(profile).getAsJsonObject();
            JsonElement id = profileObj.get("id");
            if (id == null || id.isJsonNull()) {
                return null;
            }

            String session = get("https://sessionserver.mojang.com/session/minecraft/profile/"
                    + id.getAsString() + "?unsigned=false", deadline);
            if (session == null || session.isBlank()) {
                return null;
            }
            JsonObject sessionObj = JsonParser.parseString(session).getAsJsonObject();
            for (JsonElement property : sessionObj.getAsJsonArray("properties")) {
                JsonObject propertyObj = property.getAsJsonObject();
                if ("textures".equals(propertyObj.get("name").getAsString())) {
                    String value = propertyObj.get("value").getAsString();
                    String signature = propertyObj.has("signature")
                            ? propertyObj.get("signature").getAsString() : null;
                    return new PlayerSkin(value, signature);
                }
            }
            return null;
        } catch (Exception e) {
            return null;
        }
    }

    private static String get(String url, long deadlineNanos) throws Exception {
        long remaining = deadlineNanos - System.nanoTime();
        if (remaining <= 0) {
            return null;
        }
        HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                .timeout(Duration.ofNanos(remaining))
                .header("Accept", "application/json")
                .GET()
                .build();
        HttpResponse<String> response =
                CLIENT.send(request, HttpResponse.BodyHandlers.ofString());
        return response.statusCode() == 200 ? response.body() : null;
    }
}
