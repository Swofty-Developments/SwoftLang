package net.swofty.persist.network;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import net.swofty.ScriptError;
import net.swofty.runtime.MapValue;

/**
 * The atomic write set of design 1.10.0 §3.2 — the only writes allowed against a
 * replicated global (and the only ones routed to a remote player's owner):
 * {@code add N to X}, {@code subtract N from X}, {@code append V to X},
 * {@code set X at K to V}, and an unconditional {@code set X to V}.
 *
 * <p>They are "atomic" because each one is a self-contained transformation the
 * backend applies to the stored value — never a read-modify-write in script
 * code, which is exactly the lost-update race §3.2 makes a compile error.
 */
public enum AtomicOp {
    ADD,
    SUBTRACT,
    APPEND,
    MAP_SET,
    SET;

    /**
     * Parse an op name; null when it is not an atomic op.
     *
     * <p>Two vocabularies land here. The emitted {@code "op"} key is the SURFACE
     * spelling ({@code add} / {@code subtract} / {@code append} / {@code set_at}),
     * and the emitted {@code "mutation"} key is the typechecker's refinement of
     * it against the declared value type ({@code increment} / {@code decrement} /
     * {@code append} / {@code put}). The refinement is what disambiguates
     * {@code add x to l} on a List (an append) from {@code add 50 to pot} on an
     * Integer (an increment), so both vocabularies must resolve here.
     */
    public static AtomicOp parse(String name) {
        if (name == null) {
            return null;
        }
        switch (name.toLowerCase(Locale.ROOT)) {
            case "add": case "increment": return ADD;
            case "subtract": case "decrement": return SUBTRACT;
            case "append": return APPEND;
            case "map_set": case "set_at": case "put": return MAP_SET;
            case "set": return SET;
            default: return null;
        }
    }

    /**
     * Apply this op to the current value.
     *
     * @param current  the value as it stands at the backend (never null; the
     *                 caller substitutes the declared default for a missing row)
     * @param operand  the amount / element / value
     * @param entryKey the map key for {@link #MAP_SET}, ignored otherwise
     * @return the new value to store and broadcast
     */
    public Object apply(Object current, Object operand, Object entryKey) {
        switch (this) {
            case SET:
                return operand;
            case ADD:
                return arithmetic(current, operand, true);
            case SUBTRACT:
                return arithmetic(current, operand, false);
            case APPEND: {
                List<Object> next = current instanceof List<?> list
                        ? new ArrayList<>(list) : new ArrayList<>();
                next.add(operand);
                return next;
            }
            case MAP_SET: {
                MapValue next = current instanceof MapValue map
                        ? new MapValue(map) : new MapValue();
                next.put(entryKey, operand);
                return next;
            }
            default:
                return current;
        }
    }

    private static Object arithmetic(Object current, Object operand, boolean add) {
        if (!(current instanceof Number left) || !(operand instanceof Number right)) {
            throw new ScriptError("atomic " + (add ? "add" : "subtract")
                    + " needs numbers, got " + current + " and " + operand);
        }
        boolean integral = current instanceof Integer && operand instanceof Integer;
        if (integral) {
            return add ? left.intValue() + right.intValue()
                    : left.intValue() - right.intValue();
        }
        return add ? left.doubleValue() + right.doubleValue()
                : left.doubleValue() - right.doubleValue();
    }
}
