package net.swofty.ast.nodes.statements;

import net.swofty.ast.ASTVisitor;
import net.swofty.ast.nodes.Statement;

import java.util.List;

/**
 * Block statement (multiple statements in braces)
 */
public class BlockStatement implements Statement {
    private final List<Statement> statements;

    public BlockStatement(List<Statement> statements) {
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
