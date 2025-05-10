package net.swofty.ast;

import net.swofty.ast.*;
import net.swofty.ast.nodes.Program;
import net.swofty.ast.nodes.Statement;
import net.swofty.ast.nodes.expressions.BinaryExpression;
import net.swofty.ast.nodes.expressions.StringLiteral;
import net.swofty.ast.nodes.expressions.TypeLiteral;
import net.swofty.ast.nodes.expressions.VariableReference;
import net.swofty.ast.nodes.statements.*;
import net.swofty.command.ExecutionContext;
import net.swofty.command.executors.CommandExecutor;

/**
 * Interpreter for SwoftLang scripts using the visitor pattern
 */
public class SwoftInterpreter implements ASTVisitor {
    private final ExecutionContext context;
    private Object lastValue;

    public SwoftInterpreter(ExecutionContext context) {
        this.context = context;
    }

    /**
     * Interpret a program
     */
    public void interpret(Program program) {
        program.accept(this);
    }

    @Override
    public void visit(Program program) {
        for (Statement statement : program.getStatements()) {
            if (context.isHalted()) {
                break;
            }
            statement.accept(this);
        }
    }

    @Override
    public void visit(IfStatement ifStatement) {
        // Evaluate the condition
        ifStatement.getCondition().accept(this);
        boolean conditionResult = (Boolean) lastValue;

        if (conditionResult) {
            // Execute the then branch
            ifStatement.getThenStatement().accept(this);
        } else if (ifStatement.getElseStatement() != null) {
            // Execute the else branch
            ifStatement.getElseStatement().accept(this);
        }
    }

    @Override
    public void visit(BlockStatement blockStatement) {
        for (Statement statement : blockStatement.getStatements()) {
            if (context.isHalted()) {
                break;
            }
            statement.accept(this);
        }
    }

    @Override
    public void visit(VariableAssignment variableAssignment) {
        // Evaluate the value expression
        variableAssignment.getValue().accept(this);
        Object value = lastValue;

        // Set the variable in the context
        context.setVariable(variableAssignment.getVariableName(), value);
    }

    @Override
    public void visit(SendCommand sendCommand) {
        // Get the executor for this command
        CommandExecutor executor = context.getCommandExecutor(sendCommand.getCommandName());
        if (executor == null) {
            throw new RuntimeException("No executor found for command: " + sendCommand.getCommandName());
        }

        // Execute the command
        executor.execute(sendCommand, context);
    }

    @Override
    public void visit(TeleportCommand teleportCommand) {
        // Get the executor for this command
        CommandExecutor executor = context.getCommandExecutor(teleportCommand.getCommandName());
        if (executor == null) {
            throw new RuntimeException("No executor found for command: " + teleportCommand.getCommandName());
        }

        // Execute the command
        executor.execute(teleportCommand, context);
    }

    @Override
    public void visit(HaltCommand haltCommand) {
        context.halt();
    }

    @Override
    public void visit(StringLiteral stringLiteral) {
        lastValue = stringLiteral.getValue();
    }

    @Override
    public void visit(VariableReference variableReference) {
        lastValue = context.getVariable(variableReference.getName());
    }

    @Override
    public void visit(BinaryExpression binaryExpression) {
        // Evaluate left side
        binaryExpression.getLeft().accept(this);
        Object leftValue = lastValue;

        // Evaluate right side
        binaryExpression.getRight().accept(this);
        Object rightValue = lastValue;

        // Apply the operator
        BinaryExpression.Operator operator = binaryExpression.getOperator();

        switch (operator) {
            case EQUALS:
            case NOT_EQUALS:
            case LESS_THAN:
            case GREATER_THAN:
            case LESS_THAN_EQUALS:
            case GREATER_THAN_EQUALS:
                lastValue = context.evaluateCondition(leftValue, operator.getSymbol(), rightValue);
                break;

            case AND:
                lastValue = ((Boolean) leftValue) && ((Boolean) rightValue);
                break;

            case OR:
                lastValue = ((Boolean) leftValue) || ((Boolean) rightValue);
                break;

            case IS_TYPE:
                lastValue = context.evaluateCondition(leftValue, "is", rightValue);
                break;

            case IS_NOT_TYPE:
                lastValue = context.evaluateCondition(leftValue, "is not", rightValue);
                break;

            default:
                throw new RuntimeException("Unsupported operator: " + operator);
        }
    }

    @Override
    public void visit(TypeLiteral typeLiteral) {
        lastValue = typeLiteral.getTypeName();
    }

    /**
     * Get the last evaluated value (used for testing)
     */
    public Object getLastValue() {
        return lastValue;
    }
}