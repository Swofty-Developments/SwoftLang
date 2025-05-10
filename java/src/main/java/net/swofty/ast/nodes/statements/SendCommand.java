package net.swofty.ast.nodes.statements;

import net.swofty.ast.ASTVisitor;
import net.swofty.ast.nodes.CommandStatement;
import net.swofty.ast.nodes.Expression;

import java.util.Map;

/**
 * Send command
 */
public class SendCommand extends CommandStatement {
    public SendCommand(Map<String, Expression> arguments) {
        super(arguments);
    }

    @Override
    public String getCommandName() {
        return "send";
    }

    @Override
    public void accept(ASTVisitor visitor) {
        visitor.visit(this);
    }
}