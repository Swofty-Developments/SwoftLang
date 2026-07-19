package net.swofty.packets;

import java.lang.reflect.Constructor;
import java.lang.reflect.ParameterizedType;
import java.lang.reflect.RecordComponent;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.NamedTextColor;
import net.minestom.server.coordinate.Point;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.coordinate.Vec;
import net.minestom.server.instance.block.Block;
import net.minestom.server.item.ItemStack;
import net.minestom.server.network.packet.server.SendablePacket;
import net.minestom.server.network.packet.server.ServerPacket;
import net.minestom.server.particle.Particle;
import net.minestom.server.sound.SoundEvent;
import net.swofty.ScriptError;
import net.swofty.TextFormat;
import net.swofty.items.ItemLoreBuilder;
import net.swofty.props.Coercions;
import net.swofty.props.NoneValue;
import net.swofty.runtime.Values;

/**
 * The raw-packet escape hatch (design 5D): resolves a short or fully
 * qualified class name under net.minestom.server.network.packet.server.**,
 * then constructs the packet through its canonical record constructor with
 * per-component coercion (numbers range-checked, strings into
 * Component/UUID/enum/registry values, nested records/lists/maps). Field
 * names MUST equal the record component names; missing or unknown fields
 * are runtime errors that print the full canonical shape. Version-pinned
 * to minestom-snapshots ebaa2bbf64.
 */
public final class PacketSender {
    public static final String SERVER_PACKAGE = "net.minestom.server.network.packet.server";
    public static final String CLIENT_PACKAGE = "net.minestom.server.network.packet.client";

    /** Cached reflection shape of one packet (or nested record) class. */
    public record Shape(Class<?> type, Constructor<?> ctor, RecordComponent[] components) {
        public String describe() {
            return type.getSimpleName() + "("
                    + java.util.Arrays.stream(components)
                            .map(c -> c.getName() + ": " + c.getType().getSimpleName())
                            .collect(Collectors.joining(", "))
                    + ")";
        }
    }

    private static final Map<String, Shape> SERVER_SHAPES = new ConcurrentHashMap<>();
    private static final Map<String, Class<?>> CLIENT_CLASSES = new ConcurrentHashMap<>();
    private static final Map<Class<?>, Shape> RECORD_SHAPES = new ConcurrentHashMap<>();

    private PacketSender() {
    }

    /** Resolve a server packet name: short names try .play then .common. */
    public static Shape resolveServer(String name) {
        Shape cached = SERVER_SHAPES.get(name);
        if (cached != null) {
            return cached;
        }
        Class<?> type = resolveClass(name, SERVER_PACKAGE, SendablePacket.class);
        Shape shape = shapeOf(type);
        SERVER_SHAPES.put(name, shape);
        return shape;
    }

    /** Resolve a client packet class for on packet listeners. */
    public static Class<?> resolveClient(String name) {
        return CLIENT_CLASSES.computeIfAbsent(name, n -> resolveClass(n, CLIENT_PACKAGE,
                net.minestom.server.network.packet.client.ClientPacket.class));
    }

    private static Class<?> resolveClass(String name, String basePackage, Class<?> marker) {
        List<String> candidates = new ArrayList<>();
        if (name.contains(".")) {
            if (!name.startsWith(basePackage)) {
                throw new ScriptError("packet class '" + name + "' must live under "
                        + basePackage + ".**");
            }
            candidates.add(name);
        } else {
            candidates.add(basePackage + ".play." + name);
            candidates.add(basePackage + ".common." + name);
            candidates.add(basePackage + "." + name);
        }
        for (String candidate : candidates) {
            try {
                Class<?> type = Class.forName(candidate);
                if (!marker.isAssignableFrom(type)) {
                    throw new ScriptError("class '" + candidate + "' is not a "
                            + marker.getSimpleName());
                }
                return type;
            } catch (ClassNotFoundException ignored) {
                // try the next package
            }
        }
        throw new ScriptError("unknown packet '" + name + "' (searched " + basePackage
                + ".play and .common; names are pinned to minestom-snapshots ebaa2bbf64)");
    }

    /** Canonical record constructor + components, cached per class. */
    public static Shape shapeOf(Class<?> type) {
        Shape cached = RECORD_SHAPES.get(type);
        if (cached != null) {
            return cached;
        }
        if (!type.isRecord()) {
            throw new ScriptError("packet class " + type.getSimpleName()
                    + " is not a record - cannot construct it");
        }
        RecordComponent[] components = type.getRecordComponents();
        Class<?>[] parameterTypes = new Class<?>[components.length];
        for (int i = 0; i < components.length; i++) {
            parameterTypes[i] = components[i].getType();
        }
        try {
            Constructor<?> ctor = type.getDeclaredConstructor(parameterTypes);
            ctor.setAccessible(true);
            Shape shape = new Shape(type, ctor, components);
            RECORD_SHAPES.put(type, shape);
            return shape;
        } catch (NoSuchMethodException e) {
            throw new ScriptError("no canonical constructor on " + type.getSimpleName());
        }
    }

    /** Build a server packet from script field values (strict, no fill-in). */
    public static SendablePacket build(String name, Map<String, Object> fields) {
        Shape shape = resolveServer(name);
        return (SendablePacket) construct(shape, fields, shape.type().getSimpleName());
    }

    private static Object construct(Shape shape, Map<String, Object> fields, String context) {
        RecordComponent[] components = shape.components();
        for (String key : fields.keySet()) {
            boolean known = false;
            for (RecordComponent component : components) {
                if (component.getName().equals(key)) {
                    known = true;
                    break;
                }
            }
            if (!known) {
                throw new ScriptError("packet " + context + ": unknown field '" + key
                        + "'. Expected: " + shape.describe());
            }
        }
        Object[] arguments = new Object[components.length];
        for (int i = 0; i < components.length; i++) {
            RecordComponent component = components[i];
            if (!fields.containsKey(component.getName())) {
                throw new ScriptError("packet " + context + ": missing field '"
                        + component.getName() + "' (" + component.getType().getSimpleName()
                        + "). Expected: " + shape.describe());
            }
            arguments[i] = coerce(fields.get(component.getName()), component.getType(),
                    component.getGenericType(), context + "." + component.getName(),
                    shape.type());
        }
        try {
            return shape.ctor().newInstance(arguments);
        } catch (ScriptError e) {
            throw e;
        } catch (Exception e) {
            Throwable cause = e.getCause() != null ? e.getCause() : e;
            throw new ScriptError("packet " + context + " constructor failed: "
                    + cause.getMessage() + ". Expected: " + shape.describe());
        }
    }

    /**
     * The design-5D coercion table. Nulls are only produced from an
     * explicit script none.
     */
    @SuppressWarnings({"unchecked", "rawtypes"})
    static Object coerce(Object value, Class<?> type, Type generic, String context,
            Class<?> enclosing) {
        if (NoneValue.isNone(value) || value == null) {
            if (type.isPrimitive()) {
                throw new ScriptError(context + ": none is not valid for a "
                        + type.getSimpleName());
            }
            return null;
        }
        // primitives + boxes, range-checked (overflow = error, no wrap)
        if (type == int.class || type == Integer.class) {
            return checkedLong(value, context, Integer.MIN_VALUE, Integer.MAX_VALUE).intValue();
        }
        if (type == long.class || type == Long.class) {
            return Coercions.requireNumber(value, context).longValue();
        }
        if (type == short.class || type == Short.class) {
            return checkedLong(value, context, Short.MIN_VALUE, Short.MAX_VALUE).shortValue();
        }
        if (type == byte.class || type == Byte.class) {
            return checkedLong(value, context, Byte.MIN_VALUE, Byte.MAX_VALUE).byteValue();
        }
        if (type == float.class || type == Float.class) {
            return Coercions.requireNumber(value, context).floatValue();
        }
        if (type == double.class || type == Double.class) {
            return Coercions.requireNumber(value, context).doubleValue();
        }
        if (type == boolean.class || type == Boolean.class) {
            return Coercions.toBoolean(value);
        }
        if (type == String.class) {
            return Values.displayString(value);
        }
        if (type == UUID.class) {
            if (value instanceof UUID uuid) {
                return uuid;
            }
            try {
                return UUID.fromString(Values.displayString(value));
            } catch (IllegalArgumentException e) {
                throw new ScriptError(context + ": '" + value + "' is not a UUID");
            }
        }
        if (type == Component.class) {
            if (value instanceof Component component) {
                return component;
            }
            String text = Values.displayString(value);
            return ItemLoreBuilder.isMiniMessage(text)
                    ? TextFormat.component(text)
                    : Component.text(Values.formatColorCodes(text).replace("&", "§"));
        }
        if (type.isEnum()) {
            String constant = Values.displayString(value).toUpperCase();
            try {
                return Enum.valueOf((Class<? extends Enum>) type, constant);
            } catch (IllegalArgumentException e) {
                throw new ScriptError(context + ": unknown " + type.getSimpleName() + " '"
                        + value + "' (valid: " + java.util.Arrays.stream(type.getEnumConstants())
                                .map(c -> ((Enum<?>) c).name())
                                .collect(Collectors.joining(", ")) + ")");
            }
        }
        if (type == NamedTextColor.class) {
            NamedTextColor color = value instanceof NamedTextColor named ? named
                    : NamedTextColor.NAMES.value(
                            Values.displayString(value).toLowerCase().replace(' ', '_'));
            if (color == null) {
                throw new ScriptError(context + ": unknown color '" + value + "'");
            }
            return color;
        }
        if (type == Particle.class) {
            if (value instanceof Particle particle) {
                return particle;
            }
            String key = keyed(Values.displayString(value));
            Particle particle = Particle.fromKey(key);
            if (particle == null) {
                throw new ScriptError(context + ": unknown particle '" + value + "'");
            }
            return particle;
        }
        if (type == SoundEvent.class) {
            if (value instanceof SoundEvent sound) {
                return sound;
            }
            String key = keyed(Values.displayString(value));
            SoundEvent sound = SoundEvent.fromKey(key);
            return sound != null ? sound : SoundEvent.of(key, null);
        }
        if (type == Block.class) {
            if (value instanceof Block block) {
                return block;
            }
            Block block = Block.fromKey(keyed(Values.displayString(value)));
            if (block == null) {
                throw new ScriptError(context + ": unknown block '" + value + "'");
            }
            return block;
        }
        if (type == ItemStack.class) {
            if (value instanceof ItemStack stack) {
                return stack;
            }
            throw new ScriptError(context + ": expected an item value");
        }
        if (type == Pos.class) {
            if (value instanceof Pos pos) {
                return pos;
            }
            throw new ScriptError(context + ": expected a location");
        }
        if (type == Point.class || type == Vec.class) {
            if (value instanceof Vec vec) {
                return vec;
            }
            if (value instanceof Pos pos) {
                return type == Vec.class ? new Vec(pos.x(), pos.y(), pos.z()) : pos;
            }
            throw new ScriptError(context + ": expected a location");
        }
        if (type == EnumSet.class) {
            Class<?> element = typeArgument(generic, 0);
            if (!(value instanceof List<?> list)) {
                throw new ScriptError(context + ": expected a list for an EnumSet field");
            }
            EnumSet set = EnumSet.noneOf((Class<? extends Enum>) element);
            for (Object item : list) {
                set.add((Enum) coerce(item, element, element, context + "[]", enclosing));
            }
            return set;
        }
        if (type == List.class) {
            Class<?> element = typeArgument(generic, 0);
            Type elementGeneric = genericArgument(generic, 0);
            if (!(value instanceof List<?> list)) {
                throw new ScriptError(context + ": expected a list");
            }
            List<Object> result = new ArrayList<>(list.size());
            for (Object item : list) {
                result.add(coerce(item, element, elementGeneric, context + "[]", enclosing));
            }
            return result;
        }
        if (type == Map.class) {
            Class<?> keyType = typeArgument(generic, 0);
            Class<?> valueType = typeArgument(generic, 1);
            if (!(value instanceof Map<?, ?> map)) {
                throw new ScriptError(context + ": expected a map");
            }
            Map<Object, Object> result = new LinkedHashMap<>();
            for (Map.Entry<?, ?> entry : map.entrySet()) {
                result.put(coerce(entry.getKey(), keyType, keyType, context + ".key", enclosing),
                        coerce(entry.getValue(), valueType, valueType, context + ".value",
                                enclosing));
            }
            return result;
        }
        if (type.isInstance(value)) {
            return value;
        }
        // nested record / interface component built from a { } object
        if (value instanceof Map<?, ?> map) {
            return constructNested((Map<String, Object>) map, type, context, enclosing);
        }
        throw new ScriptError(context + ": cannot convert "
                + value.getClass().getSimpleName() + " to " + type.getSimpleName());
    }

    /**
     * Nested object: a concrete record type is constructed directly; an
     * interface type (TeamsPacket$Action style) requires "type": naming a
     * member class of the enclosing packet (or a FQ-simple match) that
     * implements it.
     */
    private static Object constructNested(Map<String, Object> map, Class<?> type,
            String context, Class<?> enclosing) {
        Map<String, Object> fields = new LinkedHashMap<>(map);
        Object typeName = fields.remove("type");
        Class<?> target = type;
        if (typeName != null) {
            target = findNested(Values.displayString(typeName), type, enclosing, context);
        } else if (!type.isRecord()) {
            throw new ScriptError(context + ": " + type.getSimpleName()
                    + " is abstract - add a \"type\": \"<VariantName>\" field. Variants: "
                    + variantsOf(type, enclosing));
        }
        Shape shape = shapeOf(target);
        return construct(shape, fields, context + "(" + target.getSimpleName() + ")");
    }

    private static Class<?> findNested(String simpleName, Class<?> required,
            Class<?> enclosing, String context) {
        Class<?> outer = enclosing;
        while (outer.getEnclosingClass() != null) {
            outer = outer.getEnclosingClass();
        }
        for (Class<?> member : outer.getDeclaredClasses()) {
            if (member.getSimpleName().equals(simpleName)
                    && required.isAssignableFrom(member)) {
                return member;
            }
        }
        throw new ScriptError(context + ": unknown variant '" + simpleName + "' for "
                + required.getSimpleName() + ". Variants: " + variantsOf(required, enclosing));
    }

    private static String variantsOf(Class<?> required, Class<?> enclosing) {
        Class<?> outer = enclosing;
        while (outer.getEnclosingClass() != null) {
            outer = outer.getEnclosingClass();
        }
        List<String> names = new ArrayList<>();
        for (Class<?> member : outer.getDeclaredClasses()) {
            if (required.isAssignableFrom(member) && member.isRecord()) {
                names.add(member.getSimpleName());
            }
        }
        return names.isEmpty() ? "(none found)" : String.join(", ", names);
    }

    private static Number checkedLong(Object value, String context, long min, long max) {
        Number number = Coercions.requireNumber(value, context);
        long v = number.longValue();
        if (v < min || v > max) {
            throw new ScriptError(context + ": value " + v + " out of range [" + min
                    + ", " + max + "]");
        }
        return number;
    }

    private static String keyed(String name) {
        return name.contains(":") ? name.toLowerCase() : "minecraft:" + name.toLowerCase();
    }

    private static Class<?> typeArgument(Type generic, int index) {
        if (generic instanceof ParameterizedType parameterized) {
            Type argument = parameterized.getActualTypeArguments()[index];
            if (argument instanceof Class<?> cls) {
                return cls;
            }
            if (argument instanceof ParameterizedType nested
                    && nested.getRawType() instanceof Class<?> raw) {
                return raw;
            }
        }
        return Object.class;
    }

    private static Type genericArgument(Type generic, int index) {
        if (generic instanceof ParameterizedType parameterized) {
            return parameterized.getActualTypeArguments()[index];
        }
        return Object.class;
    }

    /** ServerPacket sanity marker used by the harness self-check. */
    public static boolean isServerPacket(Class<?> type) {
        return ServerPacket.class.isAssignableFrom(type);
    }
}
