package net.swofty.event;

import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import net.kyori.adventure.text.Component;
import net.minestom.server.coordinate.Point;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.coordinate.Vec;
import net.minestom.server.entity.EntityType;
import net.minestom.server.event.Event;
import net.minestom.server.event.entity.EntityDamageEvent;
import net.minestom.server.instance.Instance;
import net.minestom.server.instance.block.Block;
import net.minestom.server.item.ItemStack;
import net.swofty.ScriptError;
import net.swofty.TextFormat;
import net.swofty.props.Coercions;
import net.swofty.props.NoneValue;

/**
 * Cached MethodHandle bindings for the generated event property rows
 * (phase 7). Scoped to Minestom event classes ONLY: the table is built
 * from the EventCatalog, so a class outside the catalog (or outside the
 * Event hierarchy) exposes nothing. Reads go through the catalog getter
 * (getX/isX or record component); writes go through the matching
 * bean-style setX with the standard coercion table applied first.
 */
public final class EventPropertyResolver {

    /**
     * One bound property. Catalog properties bind a getter MethodHandle (and an
     * optional setter); synthetic properties (A0.3) leave the handles null and
     * carry a {@link Custom} accessor instead — e.g. the EntityDamage 'damage'
     * amount unwrapped from getDamage().
     */
    public record Handle(String name, String javaType, MethodHandle getter,
                         MethodHandle setter, Class<?> setterType, Custom custom) {

        public boolean settable() {
            return custom != null ? custom.settable() : setter != null;
        }
    }

    /**
     * A synthetic event property whose value is not a single catalog getter.
     * Registered per event class in {@link #SYNTHETIC} and overlaid onto the
     * catalog handle table. The single abstract method is {@link #read}; writes
     * default to read-only.
     */
    @FunctionalInterface
    public interface Custom {
        Object read(Event event);

        default void write(Event event, Object value) {
            throw new ScriptError("event property is read-only");
        }

        default boolean settable() {
            return false;
        }
    }

    private static final Map<Class<?>, Map<String, Handle>> CACHE = new ConcurrentHashMap<>();

    /**
     * A0.3 synthetic event properties, keyed by event class FQCN. Overlaid onto
     * the catalog handle table in {@link #build}, so a synthetic row shadows a
     * catalog getter of the same name. Currently the EntityDamage 'Damage'
     * unwrap: 'damage' amount (rw double via getAmount/setAmount), 'attacker'
     * and 'source_entity' (optional Entity), and 'damage_type' (the DamageType
     * registry key). The raw getDamage() object is never surfaced to scripts.
     */
    private static final Map<String, List<Handle>> SYNTHETIC = buildSynthetic();

    /**
     * A1/A2 friendly property aliases: a script-facing name pointing at an
     * existing catalog getter, added in {@link #build} only when the alias name
     * is otherwise free. Keeps {@code event.world} / {@code event.location}
     * consistent with {@code player.world} and the curated block events across
     * the language. The first source that exists on a given event class wins.
     */
    private static final Map<String, List<String>> ALIASES = Map.of(
            "world", List.of("instance"),
            "location", List.of("block_position", "position"));

    private static Map<String, List<Handle>> buildSynthetic() {
        Map<String, List<Handle>> synthetic = new HashMap<>();
        synthetic.put("net.minestom.server.event.entity.EntityDamageEvent", List.of(
                new Handle("damage", "double", null, null, null, new Custom() {
                    @Override
                    public Object read(Event event) {
                        return (double) ((EntityDamageEvent) event).getDamage().getAmount();
                    }

                    @Override
                    public void write(Event event, Object value) {
                        ((EntityDamageEvent) event).getDamage().setAmount(
                                ((Number) Coercions.toFloat(value)).floatValue());
                    }

                    @Override
                    public boolean settable() {
                        return true;
                    }
                }),
                new Handle("attacker", "net.minestom.server.entity.Entity", null, null, null,
                        event -> ((EntityDamageEvent) event).getDamage().getAttacker()),
                new Handle("source_entity", "net.minestom.server.entity.Entity", null, null, null,
                        event -> ((EntityDamageEvent) event).getDamage().getSource()),
                new Handle("damage_type", "java.lang.String", null, null, null, event -> {
                    var key = ((EntityDamageEvent) event).getDamage().getType();
                    return key == null ? null : key.name();
                })));
        return Map.copyOf(synthetic);
    }

    private EventPropertyResolver() {
    }

    /** The bound property table for an event class (empty if uncataloged). */
    public static Map<String, Handle> handlesFor(Class<?> eventClass) {
        return CACHE.computeIfAbsent(eventClass, EventPropertyResolver::build);
    }

    /** Read one property, converting the raw value to a script value. */
    public static Object read(net.minestom.server.event.Event event, Handle handle) {
        try {
            Object raw = handle.custom() != null
                    ? handle.custom().read(event)
                    : handle.getter().invoke(event);
            return toScriptValue(raw);
        } catch (ScriptError e) {
            throw e;
        } catch (Throwable t) {
            throw new ScriptError("failed to read event property '" + handle.name()
                    + "' on " + event.getClass().getSimpleName() + ": " + t);
        }
    }

    /** Coerce and write one property. */
    public static void write(net.minestom.server.event.Event event, Handle handle,
                             Object value) {
        if (!handle.settable()) {
            throw new ScriptError("event property '" + handle.name() + "' on "
                    + event.getClass().getSimpleName() + " is read-only");
        }
        if (handle.custom() != null) {
            // synthetic accessor does its own coercion (see the Damage unwrap)
            try {
                handle.custom().write(event, value);
            } catch (ScriptError e) {
                throw e;
            } catch (Throwable t) {
                throw new ScriptError("failed to write event property '" + handle.name()
                        + "' on " + event.getClass().getSimpleName() + ": " + t);
            }
            return;
        }
        Object coerced = coerce(value, handle.setterType(), handle.name());
        try {
            handle.setter().invoke(event, coerced);
        } catch (ScriptError e) {
            throw e;
        } catch (Throwable t) {
            throw new ScriptError("failed to write event property '" + handle.name()
                    + "' on " + event.getClass().getSimpleName() + ": " + t);
        }
    }

    /**
     * A0.4 past/future snapshot hook (infrastructure). Reads the current script
     * values of the named properties for a value-changing event so a handler can
     * later compare the pre-handler ('past') value against the mutated value.
     * Wired per event by the event-typing overlay; unused until then.
     */
    public static Map<String, Object> snapshot(net.minestom.server.event.Event event,
                                               Iterable<String> names) {
        Map<String, Handle> table = handlesFor(event.getClass());
        Map<String, Object> snap = new HashMap<>();
        for (String name : names) {
            String key = name.toLowerCase(Locale.ROOT);
            Handle handle = table.get(key);
            if (handle != null) {
                snap.put(key, read(event, handle));
            }
        }
        return Map.copyOf(snap);
    }

    // ------------------------------------------------------------------
    // table construction
    // ------------------------------------------------------------------

    private static Map<String, Handle> build(Class<?> eventClass) {
        if (!net.minestom.server.event.Event.class.isAssignableFrom(eventClass)) {
            // the resolver never reflects over non-event classes
            return Map.of();
        }
        EventCatalog.Entry entry = EventCatalog.byClassName(eventClass.getName());
        if (entry == null) {
            return Map.of();
        }
        MethodHandles.Lookup lookup = MethodHandles.publicLookup();
        Map<String, Handle> handles = new HashMap<>();
        for (EventCatalog.Property property : entry.properties()) {
            try {
                Method getterMethod = eventClass.getMethod(property.accessor());
                MethodHandle getter = lookup.unreflect(getterMethod);
                MethodHandle setter = null;
                Class<?> setterType = null;
                if (property.settable()) {
                    Method setterMethod = findSetter(eventClass, property.accessor());
                    if (setterMethod != null) {
                        setter = lookup.unreflect(setterMethod);
                        setterType = setterMethod.getParameterTypes()[0];
                    }
                }
                handles.put(property.name().toLowerCase(Locale.ROOT),
                        new Handle(property.name(), property.javaType(),
                                getter, setter, setterType, null));
            } catch (ReflectiveOperationException e) {
                System.err.println("Warning: event property '" + property.name()
                        + "' on " + eventClass.getName() + " did not bind: " + e);
            }
        }
        // A0.3: overlay synthetic accessors (Damage unwrap, ...) — a synthetic
        // row shadows a catalog getter of the same name.
        List<Handle> synthetic = SYNTHETIC.get(eventClass.getName());
        if (synthetic != null) {
            for (Handle handle : synthetic) {
                handles.put(handle.name().toLowerCase(Locale.ROOT), handle);
            }
        }
        // A1/A2 friendly aliases (world<-instance, location<-block_position/
        // position): only when the alias name is free; first present source wins.
        for (Map.Entry<String, List<String>> alias : ALIASES.entrySet()) {
            String aliasKey = alias.getKey();
            if (handles.containsKey(aliasKey)) {
                continue;
            }
            for (String source : alias.getValue()) {
                Handle src = handles.get(source);
                if (src != null) {
                    handles.put(aliasKey, new Handle(aliasKey, src.javaType(),
                            src.getter(), src.setter(), src.setterType(), src.custom()));
                    break;
                }
            }
        }
        return Map.copyOf(handles);
    }

    /** set&lt;Suffix&gt; matching a get&lt;Suffix&gt;/is&lt;Suffix&gt;/component accessor. */
    private static Method findSetter(Class<?> eventClass, String accessor) {
        String suffix;
        if (accessor.startsWith("get") && accessor.length() > 3) {
            suffix = accessor.substring(3);
        } else if (accessor.startsWith("is") && accessor.length() > 2) {
            suffix = accessor.substring(2);
        } else {
            suffix = Character.toUpperCase(accessor.charAt(0)) + accessor.substring(1);
        }
        String name = "set" + suffix;
        for (Method method : eventClass.getMethods()) {
            if (method.getName().equals(name) && method.getParameterCount() == 1
                    && !Modifier.isStatic(method.getModifiers())) {
                return method;
            }
        }
        return null;
    }

    // ------------------------------------------------------------------
    // value conversion
    // ------------------------------------------------------------------

    /** Raw getter result to script value. */
    private static Object toScriptValue(Object value) {
        if (value == null) {
            return NoneValue.INSTANCE;
        }
        if (value instanceof Component component) {
            return TextFormat.plain(component);
        }
        if (value instanceof Pos) {
            return value;
        }
        if (value instanceof Point point) {
            // BlockVec/Vec and friends: normalize to the script Location type
            return new Pos(point.x(), point.y(), point.z());
        }
        if (value instanceof Block block) {
            return block.name();
        }
        if (value instanceof Enum<?> constant) {
            return constant.name().toLowerCase(Locale.ROOT);
        }
        if (value instanceof Collection<?> collection && !(value instanceof List<?>)) {
            return new ArrayList<>(collection);
        }
        if (value instanceof Byte || value instanceof Short) {
            // byte/short getters (held-slot index, experience count) promote to
            // TInteger in the language; normalize to the runtime's canonical
            // boxed Integer so `is a Integer` and map-key coercion — both of
            // which accept only Integer/Long, never Byte/Short — hold. long
            // already satisfies both, so it is left as-is.
            return ((Number) value).intValue();
        }
        return value;
    }

    /** The standard coercion table, keyed by the setter's parameter type. */
    private static Object coerce(Object value, Class<?> target, String what) {
        if (target == boolean.class || target == Boolean.class) {
            return Coercions.toBoolean(value);
        }
        if (target == int.class || target == Integer.class) {
            return Coercions.toInt(value);
        }
        if (target == long.class || target == Long.class) {
            return Coercions.requireNumber(value, "event property '" + what + "'").longValue();
        }
        if (target == short.class || target == Short.class) {
            return Coercions.requireNumber(value, "event property '" + what + "'").shortValue();
        }
        if (target == byte.class || target == Byte.class) {
            return Coercions.requireNumber(value, "event property '" + what + "'").byteValue();
        }
        if (target == float.class || target == Float.class) {
            return Coercions.toFloat(value);
        }
        if (target == double.class || target == Double.class) {
            return Coercions.toDouble(value);
        }
        if (target == String.class) {
            return Coercions.toStringValue(value);
        }
        if (target == Component.class) {
            return Coercions.toComponent(value);
        }
        if (target == ItemStack.class) {
            return Coercions.toItemStack(value);
        }
        if (target == Pos.class) {
            return Coercions.toPos(value);
        }
        if (target == Vec.class) {
            return Coercions.toVec(value);
        }
        if (target == Point.class) {
            if (value instanceof Point point) {
                return point;
            }
            return Coercions.toPos(value);
        }
        if (target == Instance.class) {
            return Coercions.toInstance(value);
        }
        if (target == Block.class) {
            if (value instanceof Block block) {
                return block;
            }
            String name = (String) Coercions.toStringValue(value);
            String key = name.contains(":") ? name.toLowerCase(Locale.ROOT)
                    : "minecraft:" + name.toLowerCase(Locale.ROOT);
            Block block = Block.fromKey(key);
            if (block == null) {
                throw new ScriptError("unknown block '" + name + "' for event property '"
                        + what + "'");
            }
            return block;
        }
        if (target == EntityType.class) {
            if (value instanceof EntityType type) {
                return type;
            }
            return net.swofty.mobs.SwoftMob.resolveType(
                    (String) Coercions.toStringValue(value));
        }
        if (target.isEnum()) {
            String name = (String) Coercions.toStringValue(value);
            for (Object constant : target.getEnumConstants()) {
                if (((Enum<?>) constant).name().equalsIgnoreCase(name)) {
                    return constant;
                }
            }
            throw new ScriptError("unknown value '" + name + "' for event property '"
                    + what + "' (" + target.getSimpleName() + ")");
        }
        if (target.isInstance(value)) {
            return value;
        }
        throw new ScriptError("event property '" + what + "' expects a "
                + target.getSimpleName() + ", got: "
                + net.swofty.runtime.Values.displayString(value));
    }
}
