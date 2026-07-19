package net.swofty.nativebridge.execution.commands.displays;

import net.swofty.displays.SwoftDisplay;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * unmount display &lt;display&gt; (design 6B): detach from its anchor.
 */
public class UnmountDisplayStatement extends AbstractAstNode implements Statement {
    private final Expression display;

    public UnmountDisplayStatement(Expression display) {
        this.display = display;
    }

    @Override
    public void execute(ExecutionContext context) {
        ShowDisplayStatement.requireDisplay(context.evaluate(display), "unmount display")
                .unmount();
    }
}
