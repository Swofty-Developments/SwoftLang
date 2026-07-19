package net.swofty.nativebridge.execution.commands;

import net.swofty.motd.MotdRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * set server motd to &lt;expr&gt; (design 6D): swaps the ping MOTD at
 * runtime (also reachable as the server.motd property).
 */
public class SetMotdStatement extends AbstractAstNode implements Statement {
    private final Expression value;

    public SetMotdStatement(Expression value) {
        this.value = value;
    }

    @Override
    public void execute(ExecutionContext context) {
        MotdRuntime.setMotd(context.evaluateString(value));
    }
}
