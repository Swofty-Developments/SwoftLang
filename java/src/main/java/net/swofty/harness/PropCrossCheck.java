package net.swofty.harness;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.TreeMap;
import java.util.TreeSet;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import net.swofty.event.EventCatalog;
import net.swofty.event.EventPropertyResolver;
import net.swofty.event.EventType;
import net.swofty.props.PropertyDef;
import net.swofty.props.PropertyRegistry;
import net.swofty.props.PropertyTables;

/**
 * --check-props: cross-check the Java runtime property registry against the
 * compiler's --property-table contract (compiler/test/property-table.json).
 *
 * <p>For every {@code (owner, name, writable)} row the compiler emits, this
 * harness confirms the runtime can actually RESOLVE that property on the owner,
 * with matching writability. It knows about every runtime resolution mechanism,
 * not just a plain {@code DEFS} lookup:
 * <ul>
 *   <li>value owners (Player/Entity/Mob/Item/...) resolve through
 *       {@link PropertyRegistry#resolvedFor} (the exact-class + superclass +
 *       interface walk);</li>
 *   <li>curated event wrappers ({@code event:PlayerChat}, {@code event:BlockBreak},
 *       ...) resolve through their {@code SwoftXEvent} wrapper class rows;</li>
 *   <li>generic-path events ({@code event:EntityDamage}, {@code event:PlayerDeath},
 *       ...) resolve through {@link EventPropertyResolver} — the cached
 *       MethodHandle catalog accessors plus synthetic accessors plus the
 *       {@code cancelled} flag — exactly the way {@code GenericSwoftEvent} does at
 *       runtime.</li>
 * </ul>
 *
 * <p>Reports missing / wrong-writable / extra entries. Exit code is non-zero
 * when any row the compiler permits is unresolvable at runtime or resolves with
 * the wrong writability (the two categories that are genuine contract breaks).
 * With {@code --emit <path>} it also writes a golden snapshot of everything the
 * runtime resolves for each table owner, which the OCaml {@code dune test} gate
 * diffs against --property-table so the agreement cannot silently regress.
 */
public final class PropCrossCheck {

    private PropCrossCheck() {
    }

    /** compiler --property-table owner name -> the runtime class it maps to. */
    private static final Map<String, Class<?>> VALUE_OWNER = new LinkedHashMap<>();

    static {
        VALUE_OWNER.put("Player", net.minestom.server.entity.Player.class);
        VALUE_OWNER.put("Mob", net.swofty.mobs.SwoftMob.class);
        VALUE_OWNER.put("Entity", net.minestom.server.entity.Entity.class);
        VALUE_OWNER.put("Item", net.minestom.server.item.ItemStack.class);
        VALUE_OWNER.put("Location", net.minestom.server.coordinate.Pos.class);
        VALUE_OWNER.put("World", net.minestom.server.instance.Instance.class);
        VALUE_OWNER.put("Vec", net.minestom.server.coordinate.Vec.class);
        VALUE_OWNER.put("Display", net.swofty.displays.SwoftDisplay.class);
        VALUE_OWNER.put("Request", net.swofty.http.SwoftHttpRequest.class);
        VALUE_OWNER.put("Song", net.swofty.music.NbsSong.class);
        VALUE_OWNER.put("Server", net.swofty.runtime.ServerValue.class);
        VALUE_OWNER.put("Skin", net.minestom.server.entity.PlayerSkin.class);
        VALUE_OWNER.put("Canvas", net.swofty.maps.MapCanvas.class);
        VALUE_OWNER.put("OfflinePlayer", net.swofty.players.OfflinePlayerValue.class);
    }

    /**
     * Compiler event names that bind against a different engine event class than
     * their own short name (mirrors Registry.curated_emit_override /
     * curated_event_class). {@code VanillaUseItem} is delivered at runtime by the
     * generic wrapper over {@code PlayerUseItemEvent}; the catalog is keyed by the
     * engine name, so the script alias is redirected here.
     */
    private static final Map<String, String> EVENT_CLASS_OVERRIDE = Map.of(
            "VanillaUseItem", "net.minestom.server.event.player.PlayerUseItemEvent");

    private record Row(String owner, String name, boolean writable) {
    }

    public static int run(String tablePath, String emitPath) throws Exception {
        PropertyTables.ensureRegistered();

        JsonArray table = JsonParser.parseString(
                Files.readString(Path.of(tablePath))).getAsJsonArray();

        // table rows grouped by owner, in first-seen order
        Map<String, Map<String, Boolean>> tableByOwner = new LinkedHashMap<>();
        for (JsonElement el : table) {
            JsonObject o = el.getAsJsonObject();
            String owner = o.get("owner").getAsString();
            String name = o.get("name").getAsString().toLowerCase(Locale.ROOT);
            boolean writable = o.get("writable").getAsBoolean();
            tableByOwner.computeIfAbsent(owner, k -> new LinkedHashMap<>()).put(name, writable);
        }

        List<String> missing = new ArrayList<>();
        List<String> wrongWritable = new ArrayList<>();
        List<String> extra = new ArrayList<>();
        List<String> unmapped = new ArrayList<>();

        // snapshot: every runtime-resolvable (owner, name, writable) for table owners
        List<Row> snapshot = new ArrayList<>();

        for (Map.Entry<String, Map<String, Boolean>> e : tableByOwner.entrySet()) {
            String owner = e.getKey();
            Map<String, Boolean> wanted = e.getValue();

            Map<String, Boolean> runtime;
            try {
                runtime = runtimeRows(owner);
            } catch (Exception ex) {
                unmapped.add(owner + "  (" + ex.getClass().getSimpleName() + ": "
                        + ex.getMessage() + ")");
                for (String name : wanted.keySet()) {
                    missing.add(owner + "." + name + "  owner has no runtime resolver");
                }
                continue;
            }
            if (runtime == null) {
                unmapped.add(owner + "  (no runtime mapping)");
                for (String name : wanted.keySet()) {
                    missing.add(owner + "." + name + "  owner has no runtime resolver");
                }
                continue;
            }

            for (String name : new TreeSet<>(runtime.keySet())) {
                snapshot.add(new Row(owner, name, runtime.get(name)));
            }

            for (Map.Entry<String, Boolean> row : wanted.entrySet()) {
                String name = row.getKey();
                Boolean rw = runtime.get(name);
                if (rw == null) {
                    missing.add(owner + "." + name
                            + "  compiler permits it but runtime cannot resolve it");
                } else if (rw.booleanValue() != row.getValue().booleanValue()) {
                    wrongWritable.add(owner + "." + name + "  compiler="
                            + (row.getValue() ? "rw" : "ro") + " runtime="
                            + (rw ? "rw" : "ro"));
                }
            }
            for (String name : runtime.keySet()) {
                if (!wanted.containsKey(name)) {
                    extra.add(owner + "." + name
                            + "  runtime resolves it, compiler does not list it");
                }
            }
        }

        // report
        System.out.println("[CHECK-PROPS] compiler owners: " + tableByOwner.size()
                + ", table rows: " + table.size());
        printSection("MISSING (contract break)", missing);
        printSection("WRONG-WRITABLE (contract break)", wrongWritable);
        printSection("UNMAPPED OWNERS (contract break)", unmapped);
        printSection("EXTRA (runtime resolves beyond the compiler surface — informational)",
                extra);

        int breaks = missing.size() + wrongWritable.size();
        System.out.println("[CHECK-PROPS] " + (breaks == 0
                ? "PASS — runtime resolves every compiler property row"
                : breaks + " contract break(s): " + missing.size() + " missing, "
                        + wrongWritable.size() + " wrong-writable"));

        if (emitPath != null) {
            snapshot.sort((a, b) -> {
                int c = a.owner().compareTo(b.owner());
                return c != 0 ? c : a.name().compareTo(b.name());
            });
            Gson gson = new GsonBuilder().setPrettyPrinting().create();
            JsonArray out = new JsonArray();
            for (Row r : snapshot) {
                JsonObject jo = new JsonObject();
                jo.addProperty("owner", r.owner());
                jo.addProperty("name", r.name());
                jo.addProperty("writable", r.writable());
                out.add(jo);
            }
            Files.writeString(Path.of(emitPath), gson.toJson(out) + "\n");
            System.out.println("[CHECK-PROPS] wrote snapshot (" + snapshot.size()
                    + " rows) to " + emitPath);
        }

        return breaks == 0 ? 0 : 1;
    }

    /**
     * The full set of {@code name -> writable} the runtime resolves for a
     * compiler owner, or null if the owner has no runtime mapping.
     */
    private static Map<String, Boolean> runtimeRows(String owner) throws Exception {
        Class<?> valueClass = VALUE_OWNER.get(owner);
        if (valueClass != null) {
            return fromRegistry(valueClass);
        }
        if (owner.startsWith("event:")) {
            String eventName = owner.substring("event:".length());
            EventType curated = EventType.fromIdentifier(eventName);
            if (curated != null) {
                // curated wrapper: rows registered on the SwoftXEvent wrapper class
                Class<?> wrapper = Class.forName(
                        "net.swofty.event.events.Swoft" + eventName + "Event");
                return fromRegistry(wrapper);
            }
            // generic-path event: GenericSwoftEvent + EventPropertyResolver
            String override = EVENT_CLASS_OVERRIDE.get(eventName);
            Optional<EventCatalog.Entry> entry = override != null
                    ? Optional.ofNullable(EventCatalog.byClassName(override))
                    : EventCatalog.resolve(eventName);
            if (entry.isEmpty()) {
                return null;
            }
            Class<?> minestom = Class.forName(entry.get().className());
            Map<String, Boolean> rows = new LinkedHashMap<>();
            Map<String, EventPropertyResolver.Handle> handles =
                    EventPropertyResolver.handlesFor(minestom);
            for (Map.Entry<String, EventPropertyResolver.Handle> h : handles.entrySet()) {
                rows.put(h.getKey().toLowerCase(Locale.ROOT), h.getValue().settable());
            }
            // GenericSwoftEvent always exposes a writable 'cancelled' on a
            // cancellable event (routed through the underlying CancellableEvent).
            if (entry.get().cancellable()) {
                rows.put("cancelled", true);
            }
            return rows;
        }
        return null;
    }

    private static Map<String, Boolean> fromRegistry(Class<?> type) {
        Map<String, Boolean> rows = new TreeMap<>();
        for (Map.Entry<String, PropertyDef> e : PropertyRegistry.resolvedFor(type).entrySet()) {
            rows.put(e.getKey().toLowerCase(Locale.ROOT), isWritable(e.getValue()));
        }
        return rows;
    }

    /**
     * A runtime row is assignable when it has a setter OR is a real copy-hop
     * wither (immutable value types — Pos/Vec/ItemStack rebuild through the
     * wither on assignment). passThroughOnly hops (e.g. item.tags) exist only to
     * propagate deeper writes and are NOT themselves assignment targets, so they
     * read as read-only — matching how the compiler marks them.
     */
    private static boolean isWritable(PropertyDef def) {
        return def.isSettable() || (def.isCopyHop() && !def.passThroughOnly());
    }

    private static void printSection(String title, List<String> lines) {
        if (lines.isEmpty()) {
            return;
        }
        System.out.println("  -- " + title + " (" + lines.size() + ") --");
        List<String> sorted = new ArrayList<>(lines);
        sorted.sort(String::compareTo);
        for (String line : sorted) {
            System.out.println("     " + line);
        }
    }
}
