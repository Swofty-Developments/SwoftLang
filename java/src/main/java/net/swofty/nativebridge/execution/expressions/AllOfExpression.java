package net.swofty.nativebridge.execution.expressions;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;

import net.swofty.ScriptError;
import net.swofty.async.AsyncRuntime;
import net.swofty.async.FutureValue;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * {@code all of <List<Future<T>>>} → {@code Future<List<T>>} (§1.8.0):
 * resolves when EVERY member future resolves, to the list of their results in
 * input order. Backed by {@link CompletableFuture#allOf} over the member
 * futures; the combined future is tracked so a teardown cancels it too.
 */
public class AllOfExpression extends AbstractAstNode implements Expression {
    private final Expression futures;

    public AllOfExpression(Expression futures) {
        this.futures = futures;
    }

    public Expression getFutures() {
        return futures;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        List<FutureValue> members = FutureCombinators.members(context.evaluate(futures), "all of");
        CompletableFuture<?>[] cfs = new CompletableFuture<?>[members.size()];
        for (int i = 0; i < members.size(); i++) {
            cfs[i] = members.get(i).cf();
        }
        CompletableFuture<Object> combined = CompletableFuture.allOf(cfs).thenApply(ignored -> {
            List<Object> results = new ArrayList<>(members.size());
            for (FutureValue member : members) {
                Object value = member.cf().getNow(null);
                results.add(value == null ? NoneValue.INSTANCE : value);
            }
            return (Object) results;
        });
        return new FutureValue(AsyncRuntime.track(combined));
    }
}
