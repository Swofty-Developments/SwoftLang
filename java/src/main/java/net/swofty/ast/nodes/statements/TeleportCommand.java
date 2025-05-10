package net.swofty.ast.nodes.statements;

import net.swofty.ast.ASTVisitor;
import net.swofty.ast.nodes.CommandStatement;
import net.swofty.ast.nodes.Expression;

import java.util.Map;

/**
 * Teleport command
 */
public class TeleportCommand extends CommandStatement {
    public TeleportCommand(Map<String, Expression> arguments) {
        super(arguments);
    }

    @Override
    public String getCommandName() {
        return "teleport";
    }

    @Override
    public void accept(ASTVisitor visitor) {
        visitor.visit(this);
    }
}