package net.swofty.nativebridge.execution.commands;

import java.util.ArrayList;
import java.util.List;

import net.swofty.event.ReceiverDispatch;
import net.swofty.event.ReceiverDispatch.OverrideContext;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * {@code call original method [with arguments <expr>, ...]} — inside a custom
 * declaration handler that OVERRIDES a base receiver method (most-specific
 * wins), run the base {@code (receiver, method)} body. This is the replacement
 * for the removed {@code default()} / {@code super.<method>(...)} forms.
 *
 * <p>With no arguments the base method runs with the handler's CURRENT bound
 * variable values (so a mutated {@code damage}/{@code message} flows through);
 * with an explicit {@code with arguments} list those expressions are evaluated
 * and passed positionally instead. The override context is bound into scope as
 * {@code $override} by the dispatchers; when absent (the handler does not
 * override a base method) the statement is a safe no-op.
 */
public class CallOriginalStatement extends AbstractAstNode implements Statement {

    /** Explicit argument expressions, or {@code null} for the no-args form. */
    private final List<Expression> args;

    public CallOriginalStatement(List<Expression> args) {
        this.args = args;
    }

    @Override
    public void execute(ExecutionContext context) {
        if (!(context.getVariables().get("$override") instanceof OverrideContext ctx)) {
            // not overriding a base method (or run outside the dispatch path):
            // nothing to chain into — most-specific-wins with no base body
            return;
        }
        if (args == null) {
            ReceiverDispatch.invokeOriginal(ctx, context);
            return;
        }
        List<Object> values = new ArrayList<>(args.size());
        for (Expression arg : args) {
            values.add(context.evaluate(arg));
        }
        ReceiverDispatch.invokeOriginal(ctx, values);
    }
}
