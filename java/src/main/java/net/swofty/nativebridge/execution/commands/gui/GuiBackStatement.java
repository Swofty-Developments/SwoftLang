package net.swofty.nativebridge.execution.commands.gui;

import net.swofty.gui.GuiRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * go back for <player> — pop the navigation stack, close if empty
 */
public class GuiBackStatement extends AbstractAstNode implements Statement {
    private final Expression target;

    public GuiBackStatement(Expression target) {
        this.target = target;
    }

    public Expression getTarget() {
        return target;
    }

    @Override
    public void execute(ExecutionContext context) {
        GuiRuntime.goBack(context.requirePlayer(context.evaluate(target), "go back"));
    }
}
