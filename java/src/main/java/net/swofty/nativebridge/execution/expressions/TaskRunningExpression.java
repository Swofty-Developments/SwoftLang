package net.swofty.nativebridge.execution.expressions;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ExecutionContext;
import net.swofty.tasks.TaskRegistry;

/**
 * {@code <obj>.tasks.<id> is running} (W-tasks): a Boolean that is true when a
 * live task is currently scheduled on the owner under {@code id}.
 */
public class TaskRunningExpression extends AbstractAstNode implements Expression {
    private final Expression owner;
    private final String id;

    public TaskRunningExpression(Expression owner, String id) {
        this.owner = owner;
        this.id = id;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        return TaskRegistry.isRunning(context.evaluate(owner), id);
    }
}
