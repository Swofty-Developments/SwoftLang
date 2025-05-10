package net.swofty.execution.commands;

import net.swofty.execution.Expression;
import net.swofty.execution.Statement;

public class SendCommand implements Statement {
    private final Expression message;
    private final Expression target;

    public SendCommand(Expression message, Expression target) {
        this.message = message;
        this.target = target;
    }

    public Expression getMessage() {
        return message;
    }

    public Expression getTarget() {
        return target;
    }
}