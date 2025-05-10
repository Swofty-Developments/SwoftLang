package net.swofty.ast.nodes.expressions;

import net.swofty.ast.ASTVisitor;
import net.swofty.ast.nodes.Expression;

/**
 * Variable reference
 */
public class VariableReference implements Expression {
    private final String name;

    public VariableReference(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    @Override
    public void accept(ASTVisitor visitor) {
        visitor.visit(this);
    }
}
