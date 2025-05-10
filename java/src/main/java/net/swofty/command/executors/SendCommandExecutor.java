package net.swofty.command.executors;

import net.swofty.ast.nodes.CommandStatement;
import net.swofty.ast.nodes.Expression;
import net.swofty.command.ExecutionContext;

import java.util.Map; /**
 * Executor for the send command
 */
public class SendCommandExecutor extends AbstractCommandExecutor {
    public SendCommandExecutor() {
        super("send");
    }

    @Override
    public void execute(CommandStatement command, ExecutionContext context) {
        Map<String, Expression> args = command.getArguments();

        // Get the message
        Expression messageExpr = args.get("message");
        if (messageExpr == null) {
            throw new RuntimeException("Send command requires a message");
        }

        String message = (String) evaluateExpression(messageExpr, context);

        // Get the target (optional)
        Expression targetExpr = args.get("target");
        Object target = null;
        if (targetExpr != null) {
            target = evaluateExpression(targetExpr, context);
        }

        // Execute the send
        context.send(message, target);
    }
}
