package net.swofty.nativebridge.execution.commands;

import java.util.Map;

import net.minestom.server.command.CommandSender;
import net.swofty.ASTExecutor;
import net.swofty.async.AsyncRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.runtime.EnvSnapshot;
import net.swofty.runtime.ExecutionContext;

/**
 * async { ... } — anonymous fire-and-forget task
 */
public class AsyncBlockStatement extends AbstractAstNode implements Statement {
    private final ExecuteBlock body;

    public AsyncBlockStatement(ExecuteBlock body) {
        this.body = body;
    }

    public ExecuteBlock getBody() {
        return body;
    }

    @Override
    public void execute(ExecutionContext context) {
        Map<String, Object> snapshot = new EnvSnapshot().env(context.getVariables());
        CommandSender sender = context.getSender();
        ExecuteBlock block = body;
        AsyncRuntime.start("async block", () -> new ASTExecutor(sender, snapshot).execute(block));
    }
}
