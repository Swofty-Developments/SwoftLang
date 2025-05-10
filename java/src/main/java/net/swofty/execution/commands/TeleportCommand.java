package net.swofty.execution.commands;

import net.swofty.execution.Expression;
import net.swofty.execution.Statement;

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