package net.swofty.command.executors;

import net.swofty.ast.nodes.CommandStatement;
import net.swofty.ast.nodes.Expression;
import net.swofty.command.ExecutionContext;

import java.util.Map; /**
 * Executor for the teleport command
 */
public class TeleportCommandExecutor extends AbstractCommandExecutor {
    public TeleportCommandExecutor() {
        super("teleport");
    }

    @Override
    public void execute(CommandStatement command, ExecutionContext context) {
        Map<String, Expression> args = command.getArguments();

        // Get the entity to teleport
        Expression entityExpr = args.get("entity");
        if (entityExpr == null) {
            throw new RuntimeException("Teleport command requires an entity");
        }

        Object entity = evaluateExpression(entityExpr, context);

        // Get the target
        Expression targetExpr = args.get("target");
        if (targetExpr == null) {
            throw new RuntimeException("Teleport command requires a target");
        }

        Object target = evaluateExpression(targetExpr, context);

        // Execute the teleport
        context.teleport(entity, target);
    }
}
