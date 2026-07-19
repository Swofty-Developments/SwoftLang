package net.swofty.nativebridge.execution.expressions;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ExecutionContext;

public class NumberLiteral extends AbstractAstNode implements Expression {
    private final double value;
    private final boolean integer;

    public NumberLiteral(double value, boolean integer) {
        this.value = value;
        this.integer = integer;
    }

    public Object getValue() {
        return integer ? (Object) (int) value : (Object) value;
    }

    public boolean isInteger() {
        return integer;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        return getValue();
    }
}
