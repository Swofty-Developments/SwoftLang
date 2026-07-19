package net.swofty.nativebridge.execution.commands.ui;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.ui.UiRuntime;

/**
 * belowname "<text>" for p | set belowname score to <expr> for p |
 * clear belowname for p
 */
public class BelownameStatement extends AbstractAstNode implements Statement {
    public enum Action {
        TEXT,
        SCORE,
        CLEAR
    }

    private final Action action;
    private final Expression value;
    private final Expression target;

    public BelownameStatement(Action action, Expression value, Expression target) {
        this.action = action;
        this.value = value;
        this.target = target;
    }

    public Action getAction() {
        return action;
    }

    public Expression getValue() {
        return value;
    }

    public Expression getTarget() {
        return target;
    }

    @Override
    public void execute(ExecutionContext context) {
        UiRuntime.belowname(action, value != null ? context.evaluate(value) : null,
                context.evaluate(target));
    }
}
