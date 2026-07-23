package net.swofty.nativebridge.execution.expressions;

import java.util.Map;
import java.util.concurrent.CompletableFuture;

import net.minestom.server.command.CommandSender;
import net.swofty.ASTExecutor;
import net.swofty.async.AsyncRuntime;
import net.swofty.async.FutureValue;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.props.NoneValue;
import net.swofty.runtime.EnvSnapshot;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.ReturnSignal;

/**
 * {@code async { <stmts> ; <trailing-expr> }} as an EXPRESSION (§1.8.0):
 * submit the body to the virtual-thread executor and yield a {@link
 * FutureValue} whose payload is the trailing expression's value (or Unit/none
 * when there is no trailing expression). The captured environment is
 * snapshotted in the parent so writes inside the block stay task-local, just
 * like the fire-and-forget statement form.
 */
public class AsyncExprExpression extends AbstractAstNode implements Expression {
    private final ExecuteBlock body;
    private final Expression trailing;

    public AsyncExprExpression(ExecuteBlock body, Expression trailing) {
        this.body = body;
        this.trailing = trailing;
    }

    public ExecuteBlock getBody() {
        return body;
    }

    public Expression getTrailing() {
        return trailing;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        Map<String, Object> snapshot = new EnvSnapshot().env(context.getVariables());
        CommandSender sender = context.getSender();
        ExecuteBlock block = body;
        Expression trailingExpr = trailing;
        CompletableFuture<Object> future = AsyncRuntime.supply("async block", () -> {
            ExecutionContext ctx = new ASTExecutor(sender, snapshot).context();
            try {
                ctx.runBlock(block);
            } catch (ReturnSignal signal) {
                Object value = signal.getValue();
                return value == null ? NoneValue.INSTANCE : value;
            }
            if (trailingExpr == null) {
                return NoneValue.INSTANCE;
            }
            Object value = ctx.evaluate(trailingExpr);
            return value == null ? NoneValue.INSTANCE : value;
        });
        return new FutureValue(future);
    }
}
