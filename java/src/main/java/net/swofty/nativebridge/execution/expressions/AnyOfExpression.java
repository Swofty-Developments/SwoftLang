package net.swofty.nativebridge.execution.expressions;

import java.util.List;
import java.util.concurrent.CompletableFuture;

import net.swofty.async.AsyncRuntime;
import net.swofty.async.FutureValue;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;

/**
 * {@code any of <List<Future<T>>>} → {@code Future<T>} (§1.8.0): resolves to
 * the FIRST member future to resolve. Backed by {@link
 * CompletableFuture#anyOf}; the combined future is tracked so a teardown
 * cancels it too.
 */
public class AnyOfExpression extends AbstractAstNode implements Expression {
    private final Expression futures;

    public AnyOfExpression(Expression futures) {
        this.futures = futures;
    }

    public Expression getFutures() {
        return futures;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        List<FutureValue> members = FutureCombinators.members(context.evaluate(futures), "any of");
        CompletableFuture<?>[] cfs = new CompletableFuture<?>[members.size()];
        for (int i = 0; i < members.size(); i++) {
            cfs[i] = members.get(i).cf();
        }
        CompletableFuture<Object> combined = CompletableFuture.anyOf(cfs)
                .thenApply(value -> value == null ? NoneValue.INSTANCE : value);
        return new FutureValue(AsyncRuntime.track(combined));
    }
}
