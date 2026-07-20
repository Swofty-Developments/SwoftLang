package net.swofty.nativebridge.execution.commands.tasks;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.tasks.TaskRegistry;

/**
 * {@code cancel <obj>.tasks.<id>} (also spelled {@code stop <obj>.tasks.<id>})
 * (W-tasks): cancel the named task on the owner and drop it from the registry.
 * Cancelling an absent or already-finished task is a harmless no-op.
 */
public class TaskCancelStatement extends AbstractAstNode implements Statement {
    private final Expression owner;
    private final String id;

    public TaskCancelStatement(Expression owner, String id) {
        this.owner = owner;
        this.id = id;
    }

    @Override
    public void execute(ExecutionContext context) {
        TaskRegistry.cancel(context.evaluate(owner), id);
    }
}
