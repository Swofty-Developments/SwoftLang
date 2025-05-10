package net.swofty.command.executors;

import net.swofty.ast.*;
import net.swofty.ast.nodes.CommandStatement;
import net.swofty.ast.nodes.Expression;
import net.swofty.ast.nodes.expressions.StringLiteral;
import net.swofty.ast.nodes.expressions.VariableReference;
import net.swofty.command.ExecutionContext;

import java.util.Map;

/**
 * Interface for command executors
 */
public interface CommandExecutor {
    /**
     * Execute a command with given arguments
     * @param command The command to execute
     * @param context The execution context
     */
    void execute(CommandStatement command, ExecutionContext context);

    /**
     * Get the command name this executor handles
     * @return The command name
     */
    String getCommandName();
}

