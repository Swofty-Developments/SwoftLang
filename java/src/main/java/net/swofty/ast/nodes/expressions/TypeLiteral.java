package net.swofty.ast.nodes.expressions;

import net.swofty.ast.ASTVisitor;
import net.swofty.ast.nodes.Expression;

/**
 * Type literal
 */
public class TypeLiteral implements Expression {
    private final String typeName;

    public TypeLiteral(String typeName) {
        this.typeName = typeName;
    }

    public String getTypeName() {
        return typeName;
    }

    @Override
    public void accept(ASTVisitor visitor) {
        visitor.visit(this);
    }
}