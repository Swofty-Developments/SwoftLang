package net.swofty.nativebridge.execution.expressions;

import java.util.List;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ExecutionContext;

/**
 * {@code <receiver>.<name>(<args>)} as a pure expression (design
 * W-collections). Dispatch is by the receiver's runtime type (map / list /
 * String) into the shared collection-method runtime, which is a second entry
 * point onto the same implementations the free builtins use.
 */
public class MethodCallExpression extends AbstractAstNode implements Expression {
    private final Expression receiver;
    private final String name;
    private final List<Expression> args;

    public MethodCallExpression(Expression receiver, String name, List<Expression> args) {
        this.receiver = receiver;
        this.name = name;
        this.args = args;
    }

    public Expression getReceiver() {
        return receiver;
    }

    public String getName() {
        return name;
    }

    public List<Expression> getArgs() {
        return args;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        return context.callMethod(receiver, name, args);
    }
}
