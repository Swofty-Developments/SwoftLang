package net.swofty.event;

import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

/**
 * The generated Minestom event catalog (compiler/data/events.json,
 * regenerated from the pinned jar by GenMinestomCatalogs). The compiler
 * validates event names against the same file; this runtime copy maps a
 * script event name (short name, short name + "Event", or fully
 * qualified class name) to the concrete event class and its property
 * rows for the generic wrapper path.
 */
public final class EventCatalog {

    /** One generated property row (snake_case name, getter, optional setter). */
    public record Property(String name, String javaType, boolean settable, String accessor) {
    }

    /** One generated event entry. */
    public record Entry(String className, String shortName, boolean cancellable,
                        List<Property> properties) {
    }

    private static final String CATALOG_PROPERTY = "swoftlang.events-catalog";
    private static final String CATALOG_PATH = "compiler/data/events.json";

    private static volatile Map<String, Entry> byClassName;
    private static volatile Map<String, Entry> byLookupKey;
    private static volatile List<Entry> entries;

    private EventCatalog() {
    }

    /** Resolve a script event name to its catalog entry. */
    public static Optional<Entry> resolve(String name) {
        ensureLoaded();
        if (name == null || name.isBlank()) {
            return Optional.empty();
        }
        return Optional.ofNullable(byLookupKey.get(name.toLowerCase(Locale.ROOT)));
    }

    /** Entry for an exact fully-qualified class name, or null. */
    public static Entry byClassName(String className) {
        ensureLoaded();
        return byClassName.get(className);
    }

    /** All catalog entries (immutable snapshot). */
    public static List<Entry> entries() {
        ensureLoaded();
        return entries;
    }

    /** Closest short names to a misspelled event name, best first. */
    public static List<String> suggest(String name, int max) {
        ensureLoaded();
        String query = name.toLowerCase(Locale.ROOT);
        record Scored(String shortName, int distance) {
        }
        List<Scored> scored = new ArrayList<>();
        for (Entry entry : entries) {
            int distance = levenshtein(query, entry.shortName().toLowerCase(Locale.ROOT));
            if (distance <= Math.max(3, query.length() / 3)) {
                scored.add(new Scored(entry.shortName(), distance));
            }
        }
        scored.sort(Comparator.comparingInt(Scored::distance));
        List<String> result = new ArrayList<>();
        for (Scored s : scored) {
            if (result.size() >= max) {
                break;
            }
            result.add(s.shortName());
        }
        return result;
    }

    // ------------------------------------------------------------------
    // loading
    // ------------------------------------------------------------------

    private static void ensureLoaded() {
        if (byLookupKey != null) {
            return;
        }
        synchronized (EventCatalog.class) {
            if (byLookupKey != null) {
                return;
            }
            List<Entry> loaded = load();
            Map<String, Entry> classIndex = new HashMap<>();
            Map<String, Entry> lookupIndex = new HashMap<>();
            for (Entry entry : loaded) {
                classIndex.put(entry.className(), entry);
                String shortLower = entry.shortName().toLowerCase(Locale.ROOT);
                lookupIndex.putIfAbsent(shortLower, entry);
                lookupIndex.putIfAbsent(shortLower + "event", entry);
                lookupIndex.putIfAbsent(entry.className().toLowerCase(Locale.ROOT), entry);
            }
            entries = List.copyOf(loaded);
            byClassName = Map.copyOf(classIndex);
            byLookupKey = Map.copyOf(lookupIndex);
        }
    }

    private static List<Entry> load() {
        try (Reader reader = openCatalog()) {
            if (reader == null) {
                System.err.println("Warning: event catalog not found (looked at -D"
                        + CATALOG_PROPERTY + ", " + CATALOG_PATH
                        + ", classpath events.json); generic events are unavailable");
                return List.of();
            }
            return parse(JsonParser.parseReader(reader).getAsJsonObject());
        } catch (Exception e) {
            System.err.println("Warning: failed to load event catalog: " + e);
            return List.of();
        }
    }

    private static Reader openCatalog() throws Exception {
        String override = System.getProperty(CATALOG_PROPERTY);
        if (override != null && !override.isBlank()) {
            return Files.newBufferedReader(Path.of(override), StandardCharsets.UTF_8);
        }
        Path onDisk = Path.of(CATALOG_PATH);
        if (Files.isRegularFile(onDisk)) {
            return Files.newBufferedReader(onDisk, StandardCharsets.UTF_8);
        }
        InputStream fromClasspath = EventCatalog.class.getResourceAsStream("/events.json");
        if (fromClasspath != null) {
            return new InputStreamReader(fromClasspath, StandardCharsets.UTF_8);
        }
        return null;
    }

    private static List<Entry> parse(JsonObject root) {
        List<Entry> result = new ArrayList<>();
        JsonArray events = root.getAsJsonArray("events");
        if (events == null) {
            return result;
        }
        for (JsonElement element : events) {
            JsonObject event = element.getAsJsonObject();
            List<Property> properties = new ArrayList<>();
            JsonArray props = event.getAsJsonArray("properties");
            if (props != null) {
                for (JsonElement propElement : props) {
                    JsonObject prop = propElement.getAsJsonObject();
                    properties.add(new Property(
                            prop.get("name").getAsString(),
                            prop.get("javaType").getAsString(),
                            prop.get("settable").getAsBoolean(),
                            prop.get("accessor").getAsString()));
                }
            }
            result.add(new Entry(
                    event.get("className").getAsString(),
                    event.get("shortName").getAsString(),
                    event.get("cancellable").getAsBoolean(),
                    List.copyOf(properties)));
        }
        return result;
    }

    private static int levenshtein(String a, String b) {
        int[] previous = new int[b.length() + 1];
        int[] current = new int[b.length() + 1];
        for (int j = 0; j <= b.length(); j++) {
            previous[j] = j;
        }
        for (int i = 1; i <= a.length(); i++) {
            current[0] = i;
            for (int j = 1; j <= b.length(); j++) {
                int substitution = previous[j - 1]
                        + (a.charAt(i - 1) == b.charAt(j - 1) ? 0 : 1);
                current[j] = Math.min(substitution,
                        Math.min(previous[j] + 1, current[j - 1] + 1));
            }
            int[] swap = previous;
            previous = current;
            current = swap;
        }
        return previous[b.length()];
    }
}
