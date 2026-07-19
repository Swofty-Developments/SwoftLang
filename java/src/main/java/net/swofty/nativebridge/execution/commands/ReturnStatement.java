package net.swofty.nativebridge.execution.commands;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.ReturnSignal;

public class ReturnStatement extends AbstractAstNode implements Statement {
    private final Expression value;

    public ReturnStatement(Expression value) {
        this.value = value;
    }

    public Expression getValue() {
        return value;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object result = value != null ? context.evaluate(value) : null;
        throw new ReturnSignal(result);
    }
}
