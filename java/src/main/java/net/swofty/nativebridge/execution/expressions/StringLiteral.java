package net.swofty.nativebridge.execution.expressions;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Interpolator;

public class StringLiteral extends AbstractAstNode implements Expression {
    private final String value;

    public StringLiteral(String value) {
        this.value = value;
    }

    public String getValue() {
        return value;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        return Interpolator.interpolate(context, value);
    }
}
