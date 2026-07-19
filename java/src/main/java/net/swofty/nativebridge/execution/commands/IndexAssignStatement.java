package net.swofty.nativebridge.execution.commands;

import java.util.List;

import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.MapValue;
import net.swofty.runtime.Values;

/**
 * {@code set target[key] to value} (design phase-10 §1). On a map it is
 * map_set (String key); storing none deletes the row. On a list it writes an
 * existing 0-based slot; out of range is a script error. The container is a
 * mutable reference, so the write is visible through every handle to it.
 */
public class IndexAssignStatement extends AbstractAstNode implements Statement {
    private final Expression target;
    private final Expression key;
    private final Expression value;

    public IndexAssignStatement(Expression target, Expression key, Expression value) {
        this.target = target;
        this.key = key;
        this.value = value;
    }

    public Expression getTarget() {
        return target;
    }

    public Expression getKey() {
        return key;
    }

    public Expression getValue() {
        return value;
    }

    @Override
    @SuppressWarnings("unchecked")
    public void execute(ExecutionContext context) {
        Object container = context.evaluate(target);
        Object keyValue = context.evaluate(key);
        Object newValue = context.evaluate(value);
        if (container instanceof MapValue map) {
            if (NoneValue.isNone(keyValue)) {
                throw new ScriptError("map index key cannot be none");
            }
            Object mapKey = Values.coerceMapKey(keyValue);
            if (NoneValue.isNone(newValue)) {
                map.remove(mapKey);
            } else {
                map.put(mapKey, newValue);
            }
            return;
        }
        if (container instanceof List<?> list) {
            if (!(keyValue instanceof Number number)) {
                throw new ScriptError("list index must be a number, got: "
                        + Values.displayString(keyValue));
            }
            int index = number.intValue();
            if (index < 0 || index >= list.size()) {
                throw new ScriptError("list index " + index + " out of range (size "
                        + list.size() + ")");
            }
            ((List<Object>) list).set(index, newValue);
            return;
        }
        throw new ScriptError("cannot index-assign a " + Values.displayString(container));
    }
}
