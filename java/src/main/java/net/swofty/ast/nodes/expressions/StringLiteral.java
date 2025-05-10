package net.swofty.ast.nodes.expressions;

import net.swofty.ast.ASTVisitor;
import net.swofty.ast.nodes.Expression;

/**
 * String literal expression
 */
public class StringLiteral implements Expression {
    private final String value;

    public StringLiteral(String value) {
        this.value = value;
    }

    public String getValue() {
        return value;
    }

    @Override
    public void accept(ASTVisitor visitor) {
        visitor.visit(this);
    }
}
