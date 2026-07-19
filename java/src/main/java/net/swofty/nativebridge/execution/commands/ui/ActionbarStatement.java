package net.swofty.nativebridge.execution.commands.ui;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.ui.UiRuntime;

/**
 * actionbar "..." to <target> [for <duration>]; duration in ticks, null =
 * single send
 */
public class ActionbarStatement extends AbstractAstNode implements Statement {
    private final Expression text;
    private final Expression target;
    private final Integer durationTicks;

    public ActionbarStatement(Expression text, Expression target, Integer durationTicks) {
        this.text = text;
        this.target = target;
        this.durationTicks = durationTicks;
    }

    public Expression getText() {
        return text;
    }

    public Expression getTarget() {
        return target;
    }

    public Integer getDurationTicks() {
        return durationTicks;
    }

    @Override
    public void execute(ExecutionContext context) {
        UiRuntime.actionbar(context.evaluate(target), context.evaluateString(text),
                durationTicks);
    }
}
