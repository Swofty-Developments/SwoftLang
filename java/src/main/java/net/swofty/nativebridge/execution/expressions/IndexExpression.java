package net.swofty.nativebridge.execution.expressions;

import java.util.List;

import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.MapValue;
import net.swofty.runtime.Values;

/**
 * {@code target[key]} read (design phase-10 §1). On a map it is map_get:
 * a String key, absent -&gt; none. On a list it is a 0-based numeric index,
 * out of range -&gt; none. Anything else is a script error.
 */
public class IndexExpression extends AbstractAstNode implements Expression {
    private final Expression target;
    private final Expression key;

    public IndexExpression(Expression target, Expression key) {
        this.target = target;
        this.key = key;
    }

    public Expression getTarget() {
        return target;
    }

    public Expression getKey() {
        return key;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        Object container = context.evaluate(target);
        Object keyValue = context.evaluate(key);
        if (container instanceof MapValue map) {
            if (NoneValue.isNone(keyValue)) {
                throw new ScriptError("map index key cannot be none");
            }
            Object value = map.get(Values.coerceMapKey(keyValue));
            return value != null ? value : NoneValue.INSTANCE;
        }
        if (container instanceof List<?> list) {
            if (!(keyValue instanceof Number number)) {
                throw new ScriptError("list index must be a number, got: "
                        + Values.displayString(keyValue));
            }
            int index = number.intValue();
            return index >= 0 && index < list.size()
                    ? list.get(index) : NoneValue.INSTANCE;
        }
        throw new ScriptError("cannot index a " + Values.displayString(container)
                + " with [" + Values.displayString(keyValue) + "]");
    }
}
