package net.swofty.nativebridge.execution.commands.displays;

import net.swofty.displays.SwoftDisplay;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * destroy display &lt;display&gt; (design 6B): removes the entity; further
 * property writes on the value are script errors.
 */
public class DestroyDisplayStatement extends AbstractAstNode implements Statement {
    private final Expression display;

    public DestroyDisplayStatement(Expression display) {
        this.display = display;
    }

    @Override
    public void execute(ExecutionContext context) {
        ShowDisplayStatement.requireDisplay(context.evaluate(display), "destroy display")
                .destroy();
    }
}
