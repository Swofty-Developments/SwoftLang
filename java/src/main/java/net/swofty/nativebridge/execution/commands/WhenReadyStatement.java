package net.swofty.nativebridge.execution.commands;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CancellationException;
import java.util.concurrent.CompletionException;

import net.minestom.server.command.CommandSender;
import net.swofty.ASTExecutor;
import net.swofty.ScriptError;
import net.swofty.async.AsyncRuntime;
import net.swofty.async.FutureValue;
import net.swofty.async.HaltSignal;
import net.swofty.async.TickDispatch;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.props.NoneValue;
import net.swofty.runtime.EnvSnapshot;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * {@code when <Future<T>> is ready as <name> { <body> }} (§1.8.0): register a
 * continuation that, when the future resolves, runs {@code <body>} back on the
 * TICK thread with {@code <name>} bound to the {@code T}. This is the
 * CompletableFuture callback model — legal in tick context, it does not block.
 *
 * <ul>
 *   <li>Normal completion: schedule the body on the next tick with the result
 *       bound.</li>
 *   <li>Error (a runtime error inside the async body): log and skip the body —
 *       there is no error branch to route it to (§5).</li>
 *   <li>Cancellation (reload/shutdown teardown): skip silently.</li>
 * </ul>
 *
 * <p>The continuation captures the program generation it was registered under
 * and refuses to fire once a reload has advanced it, so a body can never run
 * against a torn-down program even if the future resolved just before the
 * reload (see {@link AsyncRuntime#generation()}).
 */
public class WhenReadyStatement extends AbstractAstNode implements Statement {
    private final Expression future;
    private final String name;
    private final ExecuteBlock body;

    public WhenReadyStatement(Expression future, String name, ExecuteBlock body) {
        this.future = future;
        this.name = name;
        this.body = body;
    }

    public Expression getFuture() {
        return future;
    }

    public String getName() {
        return name;
    }

    public ExecuteBlock getBody() {
        return body;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object value = context.evaluate(future);
        if (!(value instanceof FutureValue futureValue)) {
            throw new ScriptError("when ... is ready expects a Future, got: "
                    + Values.displayString(value));
        }
        Map<String, Object> snapshot = new EnvSnapshot().env(context.getVariables());
        CommandSender sender = context.getSender();
        String bindName = name;
        ExecuteBlock block = body;
        long generation = AsyncRuntime.generation();

        futureValue.cf().whenComplete((result, error) -> {
            if (error != null) {
                Throwable cause = error;
                while (cause instanceof CompletionException && cause.getCause() != null) {
                    cause = cause.getCause();
                }
                if (cause instanceof CancellationException || cause instanceof HaltSignal) {
                    return; // teardown — skip silently
                }
                System.err.println("[when ... is ready] future failed, body skipped: " + cause);
                return;
            }
            TickDispatch.runNextTick(() -> {
                if (AsyncRuntime.generation() != generation) {
                    return; // program was torn down between resolve and tick
                }
                Map<String, Object> variables = new HashMap<>(snapshot);
                variables.put(bindName, result == null ? NoneValue.INSTANCE : result);
                new ASTExecutor(sender, variables).execute(block);
            });
        });
    }
}
