package net.swofty.ast;

import net.swofty.ast.nodes.Program;
import net.swofty.ast.nodes.expressions.*;
import net.swofty.ast.nodes.statements.*;

/**
 * Visitor interface for traversing the AST
 */
public interface ASTVisitor {
    void visit(Program program);
    void visit(IfStatement ifStatement);
    void visit(BlockStatement blockStatement);
    void visit(VariableAssignment variableAssignment);
    void visit(SendCommand sendCommand);
    void visit(TeleportCommand teleportCommand);
    void visit(HaltCommand haltCommand);
    void visit(StringLiteral stringLiteral);
    void visit(VariableReference variableReference);
    void visit(BinaryExpression binaryExpression);
    void visit(TypeLiteral typeLiteral);
}