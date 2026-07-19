package net.swofty.nativebridge.execution.commands.ui;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.ui.UiRuntime;

public class ShowScoreboardStatement extends AbstractAstNode implements Statement {
    private final String name;
    private final Expression target;

    public ShowScoreboardStatement(String name, Expression target) {
        this.name = name;
        this.target = target;
    }

    public String getName() {
        return name;
    }

    public Expression getTarget() {
        return target;
    }

    @Override
    public void execute(ExecutionContext context) {
        UiRuntime.showScoreboard(name, context.evaluate(target));
    }
}
