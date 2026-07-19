package net.swofty.nativebridge.execution.expressions;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ExecutionContext;

public class TypeLiteral extends AbstractAstNode implements Expression {
    private final String typeName;

    public TypeLiteral(String typeName) {
        this.typeName = typeName;
    }

    public String getTypeName() {
        return typeName;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        return typeName;
    }
}
