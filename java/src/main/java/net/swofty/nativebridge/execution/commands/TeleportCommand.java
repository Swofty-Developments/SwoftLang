package net.swofty.nativebridge.execution.commands;

import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;

public class TeleportCommand implements Statement {
    private final Expression entity;
    private final Expression target;

    public TeleportCommand(Expression entity, Expression target) {
        this.entity = entity;
        this.target = target;
    }

    public Expression getEntity() {
        return entity;
    }

    public Expression getTarget() {
        return target;
    }
}