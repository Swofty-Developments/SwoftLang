package net.swofty.nativebridge.execution.commands;

import net.swofty.event.ReceiverDispatch;
import net.swofty.event.ReceiverDispatch.OverrideContext;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * {@code call original method} — inside a custom declaration handler that
 * OVERRIDES a base receiver method (most-specific wins), run the base
 * {@code (receiver, method)} body. This is the replacement for the removed
 * {@code default()} / {@code super.<method>(...)} forms.
 *
 * <p>The base method runs with the handler's CURRENT bound variable values (so
 * a mutated {@code damage}/{@code message} flows through) — forward a changed
 * value by mutating the bound variable before the call. The override context is
 * bound into scope as {@code $override} by the dispatchers; when absent (the
 * handler does not override a base method) the statement is a safe no-op.
 */
public class CallOriginalStatement extends AbstractAstNode implements Statement {

    public CallOriginalStatement() {
    }

    @Override
    public void execute(ExecutionContext context) {
        if (!(context.getVariables().get("$override") instanceof OverrideContext ctx)) {
            // not overriding a base method (or run outside the dispatch path):
            // nothing to chain into — most-specific-wins with no base body
            return;
        }
        ReceiverDispatch.invokeOriginal(ctx, context);
    }
}
