package net.swofty.ast.nodes;

import net.swofty.ast.ASTNode;
import net.swofty.ast.ASTVisitor;

import java.util.List;

/**
 * Program (root node)
 */
public class Program implements ASTNode {
    private final List<Statement> statements;

    public Program(List<Statement> statements) {
        this.statements = statements;
    }

    public List<Statement> getStatements() {
        return statements;
    }

    @Override
    public void accept(ASTVisitor visitor) {
        visitor.visit(this);
    }
}
