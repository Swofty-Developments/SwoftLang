package net.swofty.execution.expressions;

import net.swofty.execution.Expression;

public class TypeLiteral implements Expression {
    private final String typeName;

    public TypeLiteral(String typeName) {
        this.typeName = typeName;
    }

    public String getTypeName() {
        return typeName;
    }
}
