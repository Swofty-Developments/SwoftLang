package net.swofty.nativebridge.execution.commands.ui;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.ui.UiRuntime;

/**
 * set tablist header|footer to <expr> for <target>
 */
public class SetTablistPartStatement extends AbstractAstNode implements Statement {
    public enum Part {
        HEADER,
        FOOTER
    }

    private final Part part;
    private final Expression value;
    private final Expression target;

    public SetTablistPartStatement(Part part, Expression value, Expression target) {
        this.part = part;
        this.value = value;
        this.target = target;
    }

    public Part getPart() {
        return part;
    }

    public Expression getValue() {
        return value;
    }

    public Expression getTarget() {
        return target;
    }

    @Override
    public void execute(ExecutionContext context) {
        UiRuntime.setTablistPart(part, context.evaluateString(value),
                context.evaluate(target));
    }
}
