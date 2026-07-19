package net.swofty.nativebridge.execution.commands.ui;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.ui.UiRuntime;

/**
 * set bossbar "name" progress|text to <expr> for <target>
 */
public class SetBossbarPartStatement extends AbstractAstNode implements Statement {
    public enum Part {
        PROGRESS,
        TEXT
    }

    private final String name;
    private final Part part;
    private final Expression value;
    private final Expression target;

    public SetBossbarPartStatement(String name, Part part, Expression value, Expression target) {
        this.name = name;
        this.part = part;
        this.value = value;
        this.target = target;
    }

    public String getName() {
        return name;
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
        UiRuntime.setBossbarPart(name, part, context.evaluate(value),
                context.evaluate(target));
    }
}
