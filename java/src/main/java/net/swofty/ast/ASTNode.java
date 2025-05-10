package net.swofty.ast;

/**
 * Base interface for all AST nodes
 */
public interface ASTNode {
    void accept(ASTVisitor visitor);
}
