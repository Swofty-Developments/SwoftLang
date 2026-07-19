package net.swofty.nativebridge.execution.expressions;

import java.util.List;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ExecutionContext;

public class FunctionCallExpression extends AbstractAstNode implements Expression {
    private final String name;
    private final List<Expression> args;

    public FunctionCallExpression(String name, List<Expression> args) {
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
    public Object evaluate(ExecutionContext context) {
        return context.callFunction(name, args);
    }
}
