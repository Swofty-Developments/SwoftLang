package net.swofty.ast.nodes.statements;

import net.swofty.ast.ASTVisitor;
import net.swofty.ast.nodes.Expression;
import net.swofty.ast.nodes.Statement;

/**
 * If statement
 */
public class IfStatement implements Statement {
    private final Expression condition;
    private final Statement thenStatement;
    private final Statement elseStatement; // Can be null

    public IfStatement(Expression condition, Statement thenStatement, Statement elseStatement) {
        this.condition = condition;
        this.thenStatement = thenStatement;
        this.elseStatement = elseStatement;
    }

    public Expression getCondition() {
        return condition;
    }

    public Statement getThenStatement() {
        return thenStatement;
    }

    public Statement getElseStatement() {
        return elseStatement;
    }

    @Override
    public void accept(ASTVisitor visitor) {
        visitor.visit(this);
    }
}