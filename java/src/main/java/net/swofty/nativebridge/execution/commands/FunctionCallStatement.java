package net.swofty.nativebridge.execution.commands;

import java.util.List;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

public class FunctionCallStatement extends AbstractAstNode implements Statement {
    private final String name;
    private final List<Expression> args;

    public FunctionCallStatement(String name, List<Expression> args) {
        this.name = name;
        this.args = args;
    }

    public String getName() {
        return name;
    }

    public List<Expression> getArgs() {
        return args;
    }

    @Override
    public void execute(ExecutionContext context) {
        context.callFunction(name, args);
    }
}
