package net.swofty.nativebridge.execution.commands;

import java.util.List;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * {@code <receiver>.<name>(<args>)} as a bare statement (design
 * W-collections). Used for the in-place mutating collection methods
 * (list.add / map.set / ...); dispatch shares the same runtime as the
 * expression form and mutates the live receiver value.
 */
public class MethodCallStatement extends AbstractAstNode implements Statement {
    private final Expression receiver;
    private final String name;
    private final List<Expression> args;

    public MethodCallStatement(Expression receiver, String name, List<Expression> args) {
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
    public void execute(ExecutionContext context) {
        context.callMethod(receiver, name, args);
    }
}
