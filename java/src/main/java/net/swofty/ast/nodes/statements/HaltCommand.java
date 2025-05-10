package net.swofty.ast.nodes.statements;

import net.swofty.ast.ASTVisitor;
import net.swofty.ast.nodes.Statement;

/**
 * Halt command
 */
public class HaltCommand implements Statement {
    @Override
    public void accept(ASTVisitor visitor) {
        visitor.visit(this);
    }
}
