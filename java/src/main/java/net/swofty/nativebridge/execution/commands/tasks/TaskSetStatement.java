package net.swofty.nativebridge.execution.commands.tasks;

import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;
import net.swofty.sched.ScheduleHandle;
import net.swofty.tasks.TaskRegistry;

/**
 * {@code set <obj>.tasks.<id> to schedule ...} (W-tasks): associate a named
 * task with an owner. The value must evaluate to a {@link ScheduleHandle} — the
 * {@code schedule ...} expression starts the tick-aligned loop and hands its
 * handle here, where it is stored under (owner-identity, id). Re-assigning the
 * same id cancels the previously stored task first.
 */
public class TaskSetStatement extends AbstractAstNode implements Statement {
    private final Expression owner;
    private final String id;
    private final Expression value;

    public TaskSetStatement(Expression owner, String id, Expression value) {
        this.owner = owner;
        this.id = id;
        this.value = value;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object ownerValue = context.evaluate(owner);
        Object taskValue = context.evaluate(value);
        if (!(taskValue instanceof ScheduleHandle handle)) {
            throw new ScriptError("a task must be a schedule (from a 'schedule ...' expression), "
                    + "got: " + Values.displayString(taskValue));
        }
        TaskRegistry.set(ownerValue, id, handle);
    }
}
