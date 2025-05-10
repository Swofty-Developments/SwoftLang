package net.swofty.ast.nodes.statements;

import net.swofty.ast.ASTVisitor;
import net.swofty.ast.nodes.Expression;
import net.swofty.ast.nodes.Statement;

/**
 * Variable assignment
 */
public class VariableAssignment implements Statement {
    private final String variableName;
    private final Expression value;

    public VariableAssignment(String variableName, Expression value) {
        this.variableName = variableName;
        this.value = value;
    }

    public String getVariableName() {
        return variableName;
    }

    public Expression getValue() {
        return value;
    }

    @Override
    public void accept(ASTVisitor visitor) {
        visitor.visit(this);
    }
}
