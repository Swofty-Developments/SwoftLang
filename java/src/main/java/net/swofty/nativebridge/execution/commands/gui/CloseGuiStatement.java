package net.swofty.nativebridge.execution.commands.gui;

import net.swofty.gui.GuiRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

public class CloseGuiStatement extends AbstractAstNode implements Statement {
    private final Expression target;

    public CloseGuiStatement(Expression target) {
        this.target = target;
    }

    public Expression getTarget() {
        return target;
    }

    @Override
    public void execute(ExecutionContext context) {
        GuiRuntime.closeGui(context.requirePlayer(context.evaluate(target), "close gui"));
    }
}
