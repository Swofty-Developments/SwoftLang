package net.swofty.nativebridge.execution.commands.ui;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.ui.UiRuntime;

public class ClearTitleStatement extends AbstractAstNode implements Statement {
    private final Expression target;

    public ClearTitleStatement(Expression target) {
        this.target = target;
    }

    public Expression getTarget() {
        return target;
    }

    @Override
    public void execute(ExecutionContext context) {
        UiRuntime.clearTitle(context.evaluate(target));
    }
}
