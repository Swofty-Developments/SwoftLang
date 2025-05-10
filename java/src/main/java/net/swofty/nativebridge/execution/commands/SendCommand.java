package net.swofty.nativebridge.execution.commands;

import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;

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