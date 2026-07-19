package net.swofty.nativebridge.execution.expressions;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.props.PathResolver;
import net.swofty.runtime.ExecutionContext;

/**
 * Structured property access: event.player.name parses as
 * prop(prop(var event, "player"), "name")
 */
public class PropertyAccessExpression extends AbstractAstNode implements Expression {
    private final Expression target;
    private final String name;

    public PropertyAccessExpression(Expression target, String name) {
        this.target = target;
        this.name = name;
    }

    public Expression getTarget() {
        return target;
    }

    public String getName() {
        return name;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        Object value = context.evaluate(target);
        return PathResolver.getProperty(value, name, getLine(), getCol());
    }
}
