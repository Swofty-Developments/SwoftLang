package net.swofty.nativebridge.execution.commands;

import java.util.ArrayList;
import java.util.List;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.nativebridge.execution.expressions.PropertyAccessExpression;
import net.swofty.nativebridge.execution.expressions.VariableReference;
import net.swofty.props.PathResolver;
import net.swofty.runtime.ExecutionContext;

/**
 * set a.b.c to v — parser splits into target=a.b, name=c, value=v
 */
public class SetPropertyStatement extends AbstractAstNode implements Statement {
    private final Expression target;
    private final String name;
    private final Expression value;

    public SetPropertyStatement(Expression target, String name, Expression value) {
        this.target = target;
        this.name = name;
        this.value = value;
    }

    public Expression getTarget() {
        return target;
    }

    public String getName() {
        return name;
    }

    public Expression getValue() {
        return value;
    }

    @Override
    public void execute(ExecutionContext context) {
        List<String> names = new ArrayList<>();
        names.add(name);
        Expression cursor = target;
        while (cursor instanceof PropertyAccessExpression prop) {
            names.add(0, prop.getName());
            cursor = prop.getTarget();
        }

        Object evaluated = context.evaluate(value);
        int line = getLine();
        int col = getCol();
        if (cursor instanceof VariableReference varRef && !varRef.getName().contains(".")) {
            PathResolver.assignVariablePath(context.getVariables(), varRef.getName(), names,
                    evaluated, line, col);
        } else {
            PathResolver.assignObjectPath(context.evaluate(cursor), names, evaluated, line, col);
        }
    }
}
