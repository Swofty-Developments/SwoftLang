package net.swofty.command.executors;

import net.swofty.ast.nodes.Expression;
import net.swofty.ast.nodes.expressions.StringLiteral;
import net.swofty.ast.nodes.expressions.VariableReference;
import net.swofty.command.ExecutionContext;

/**
 * Base class for command executors
 */
public abstract class AbstractCommandExecutor implements CommandExecutor {
    protected final String commandName;

    protected AbstractCommandExecutor(String commandName) {
        this.commandName = commandName;
    }

    @Override
    public String getCommandName() {
        return commandName;
    }

    /**
     * Helper to evaluate an expression in the given context
     */
    protected Object evaluateExpression(Expression expr, ExecutionContext context) {
        if (expr instanceof StringLiteral) {
            String value = ((StringLiteral) expr).getValue();
            // Process string interpolation
            return context.interpolateString(value);
        } else if (expr instanceof VariableReference) {
            String varName = ((VariableReference) expr).getName();
            return context.getVariable(varName);
        }

        throw new RuntimeException("Unsupported expression type: " + expr.getClass().getSimpleName());
    }
}
