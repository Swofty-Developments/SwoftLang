package net.swofty.nativebridge.execution.expressions;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;

public class NoneLiteral extends AbstractAstNode implements Expression {

    @Override
    public Object evaluate(ExecutionContext context) {
        return NoneValue.INSTANCE;
    }
}
