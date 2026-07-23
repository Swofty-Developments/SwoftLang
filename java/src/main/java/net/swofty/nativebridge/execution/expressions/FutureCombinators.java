package net.swofty.nativebridge.execution.expressions;

import java.util.ArrayList;
import java.util.List;

import net.swofty.ScriptError;
import net.swofty.async.FutureValue;
import net.swofty.runtime.Values;

/** Shared coercion for the {@code all of}/{@code any of} combinators. */
final class FutureCombinators {
    private FutureCombinators() {
    }

    /**
     * Coerce a combinator operand to its list of {@link FutureValue} members.
     * The compiler guarantees {@code List<Future<T>>}; this re-checks at runtime
     * (the operand may have arrived as {@code Any}).
     */
    static List<FutureValue> members(Object value, String what) {
        if (!(value instanceof List<?> list)) {
            throw new ScriptError(what + " expects a list of futures, got: "
                    + Values.displayString(value));
        }
        List<FutureValue> members = new ArrayList<>(list.size());
        for (Object element : list) {
            if (!(element instanceof FutureValue futureValue)) {
                throw new ScriptError(what + " expects a list of futures, but an "
                        + "element was: " + Values.displayString(element));
            }
            members.add(futureValue);
        }
        return members;
    }
}
