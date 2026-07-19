package net.swofty.nativebridge.execution.commands.ui;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * line "text" inside a scoreboard lines block; null text = blank
 */
public class LineStatement extends AbstractAstNode implements Statement {
    private final Expression text;

    public LineStatement(Expression text) {
        this.text = text;
    }

    public Expression getText() {
        return text;
    }

    public boolean isBlank() {
        return text == null;
    }

    @Override
    public void execute(ExecutionContext context) {
        context.emitUi(this);
    }
}
