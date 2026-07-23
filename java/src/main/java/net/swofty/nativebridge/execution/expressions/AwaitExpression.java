package net.swofty.nativebridge.execution.expressions;

import java.util.concurrent.CancellationException;
import java.util.concurrent.CompletionException;
import java.util.concurrent.ExecutionException;

import net.swofty.ScriptError;
import net.swofty.async.FutureValue;
import net.swofty.async.HaltSignal;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * {@code await <Future<T>>} → {@code T} (§1.8.0). Parks the (cheap) virtual
 * thread on {@code cf.get()} until the future resolves; returns instantly if it
 * is already done. Legal only in async context — the compiler's color check
 * (same gate as {@code wait}) guarantees that, so no runtime gate here.
 *
 * <ul>
 *   <li>Exceptional completion (a runtime error inside the async body)
 *       re-raises the original {@code ScriptError} in this awaiting context, so
 *       it propagates like any other runtime error.</li>
 *   <li>Cancellation (reload/shutdown teardown) unwinds this vthread cleanly
 *       via {@link HaltSignal} — the program is being torn down, not a handled
 *       error.</li>
 * </ul>
 */
public class AwaitExpression extends AbstractAstNode implements Expression {
    private final Expression future;

    public AwaitExpression(Expression future) {
        this.future = future;
    }

    public Expression getFuture() {
        return future;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        Object value = context.evaluate(future);
        if (!(value instanceof FutureValue futureValue)) {
            throw new ScriptError("await expects a Future, got: "
                    + Values.displayString(value));
        }
        try {
            Object result = futureValue.cf().get();
            return result == null ? NoneValue.INSTANCE : result;
        } catch (InterruptedException e) {
            // this awaiting task was interrupted (teardown) — unwind cleanly
            Thread.currentThread().interrupt();
            throw new HaltSignal();
        } catch (CancellationException e) {
            // the awaited future was cancelled (teardown) — unwind cleanly
            throw new HaltSignal();
        } catch (ExecutionException e) {
            throw reraise(e.getCause());
        }
    }

    /** Re-raise the async body's failure in this context. */
    private RuntimeException reraise(Throwable cause) {
        Throwable unwrapped = cause;
        while (unwrapped instanceof CompletionException && unwrapped.getCause() != null) {
            unwrapped = unwrapped.getCause();
        }
        if (unwrapped instanceof CancellationException) {
            // a combinator (all of / any of) member was cancelled on teardown
            return new HaltSignal();
        }
        if (unwrapped instanceof HaltSignal halt) {
            return halt;
        }
        if (unwrapped instanceof ScriptError scriptError) {
            return scriptError;
        }
        if (unwrapped instanceof RuntimeException runtime) {
            return runtime;
        }
        return new ScriptError("async task failed: "
                + (unwrapped == null ? "unknown error" : unwrapped.getMessage()));
    }
}
