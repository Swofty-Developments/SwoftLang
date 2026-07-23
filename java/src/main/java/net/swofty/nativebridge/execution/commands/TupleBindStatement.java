package net.swofty.nativebridge.execution.commands;

import java.util.List;

import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * {@code set (a, b) to <expr>} positional tuple destructure (§4). Scoped to
 * {@code await all of [...]} for 1.8.0: the value is the ordered result list of
 * an {@code all of} combinator, whose elements are bound to the names
 * positionally (the compiler tracks the heterogeneous element types).
 */
public class TupleBindStatement extends AbstractAstNode implements Statement {
    private final List<String> names;
    private final Expression value;

    public TupleBindStatement(List<String> names, Expression value) {
        this.names = names;
        this.value = value;
    }

    public List<String> getNames() {
        return names;
    }

    public Expression getValue() {
        return value;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object evaluated = context.evaluate(value);
        if (!(evaluated instanceof List<?> list)) {
            throw new ScriptError("tuple binding expects a list of "
                    + names.size() + " values, got: " + Values.displayString(evaluated));
        }
        for (int i = 0; i < names.size(); i++) {
            Object element = i < list.size() ? list.get(i) : NoneValue.INSTANCE;
            context.getVariables().put(names.get(i),
                    element == null ? NoneValue.INSTANCE : element);
        }
    }
}
