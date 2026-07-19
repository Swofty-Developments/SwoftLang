package net.swofty.items;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import net.kyori.adventure.nbt.BinaryTag;
import net.kyori.adventure.nbt.ByteBinaryTag;
import net.kyori.adventure.nbt.CompoundBinaryTag;
import net.kyori.adventure.nbt.DoubleBinaryTag;
import net.kyori.adventure.nbt.FloatBinaryTag;
import net.kyori.adventure.nbt.IntBinaryTag;
import net.kyori.adventure.nbt.ListBinaryTag;
import net.kyori.adventure.nbt.LongBinaryTag;
import net.kyori.adventure.nbt.StringBinaryTag;
import net.swofty.ScriptError;
import net.swofty.props.NoneValue;
import net.swofty.runtime.Values;

/**
 * Converts between the script-side nested tag tree (LinkedHashMap /
 * List / scalars) and adventure NBT (CompoundBinaryTag / ListBinaryTag /
 * scalar tags), so item.tags round-trips through the real ItemStack NBT
 * (phase 9 §2). Booleans travel as NBT bytes and read back as Boolean;
 * whole-number scalars stay Integer, fractional stay Double, everything
 * else stringifies.
 */
public final class NbtCodec {

    private NbtCodec() {
    }

    /** Script tree -> NBT compound. */
    public static CompoundBinaryTag toCompound(Map<String, Object> tree) {
        CompoundBinaryTag.Builder builder = CompoundBinaryTag.builder();
        for (Map.Entry<String, Object> entry : tree.entrySet()) {
            if (NoneValue.isNone(entry.getValue())) {
                continue;
            }
            builder.put(entry.getKey(), toBinary(entry.getValue()));
        }
        return builder.build();
    }

    /** One script value -> its NBT tag (scalar, list, or nested compound). */
    @SuppressWarnings("unchecked")
    public static BinaryTag toBinary(Object value) {
        if (value instanceof Boolean b) {
            return ByteBinaryTag.byteBinaryTag((byte) (b ? 1 : 0));
        }
        if (value instanceof Integer i) {
            return IntBinaryTag.intBinaryTag(i);
        }
        if (value instanceof Long l) {
            return LongBinaryTag.longBinaryTag(l);
        }
        if (value instanceof Float f) {
            return FloatBinaryTag.floatBinaryTag(f);
        }
        if (value instanceof Double d) {
            return DoubleBinaryTag.doubleBinaryTag(d);
        }
        if (value instanceof Number n) {
            return DoubleBinaryTag.doubleBinaryTag(n.doubleValue());
        }
        if (value instanceof String s) {
            return StringBinaryTag.stringBinaryTag(s);
        }
        if (value instanceof Map<?, ?> map) {
            return toCompound((Map<String, Object>) map);
        }
        if (value instanceof List<?> list) {
            List<BinaryTag> elements = new ArrayList<>();
            for (Object element : list) {
                if (!NoneValue.isNone(element)) {
                    elements.add(toBinary(element));
                }
            }
            if (elements.isEmpty()) {
                return ListBinaryTag.empty();
            }
            try {
                return ListBinaryTag.from(elements);
            } catch (IllegalArgumentException e) {
                // NBT lists are homogeneous; a mixed script list is stored
                // as its string projection so it still round-trips as text
                List<BinaryTag> strings = new ArrayList<>();
                for (Object element : list) {
                    strings.add(StringBinaryTag.stringBinaryTag(Values.displayString(element)));
                }
                return ListBinaryTag.from(strings);
            }
        }
        return StringBinaryTag.stringBinaryTag(Values.displayString(value));
    }

    /** NBT compound -> script tree (insertion order preserved best-effort). */
    public static Map<String, Object> fromCompound(CompoundBinaryTag tag) {
        Map<String, Object> tree = new LinkedHashMap<>();
        for (String key : tag.keySet()) {
            tree.put(key, fromBinary(tag.get(key)));
        }
        return tree;
    }

    /** One NBT tag -> its script value. */
    public static Object fromBinary(BinaryTag tag) {
        if (tag instanceof ByteBinaryTag b) {
            // booleans are the only bytes this codec ever writes
            return b.value() != 0;
        }
        if (tag instanceof IntBinaryTag i) {
            return i.value();
        }
        if (tag instanceof LongBinaryTag l) {
            return l.value();
        }
        if (tag instanceof FloatBinaryTag f) {
            return (double) f.value();
        }
        if (tag instanceof DoubleBinaryTag d) {
            return d.value();
        }
        if (tag instanceof StringBinaryTag s) {
            return s.value();
        }
        if (tag instanceof CompoundBinaryTag compound) {
            return fromCompound(compound);
        }
        if (tag instanceof ListBinaryTag list) {
            List<Object> values = new ArrayList<>();
            for (BinaryTag element : list) {
                values.add(fromBinary(element));
            }
            return values;
        }
        throw new ScriptError("unsupported NBT tag type: " + tag.type());
    }
}
