package net.swofty.nativebridge.execution.commands.sched;

import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;
import net.swofty.sched.ScheduleHandle;
import net.swofty.sched.ScheduleRegistry;

/**
 * cancel schedule &lt;expr&gt; (design 6D + scheduler v2): the operand may be a
 * schedule handle OR a String name (cancel-by-name). Cancelling something
 * already stopped, or an unknown name, is a harmless no-op.
 */
public class CancelScheduleStatement extends AbstractAstNode implements Statement {
    private final Expression schedule;

    public CancelScheduleStatement(Expression schedule) {
        this.schedule = schedule;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object value = context.evaluate(schedule);
        if (value instanceof ScheduleHandle handle) {
            handle.cancel();
            return;
        }
        if (value instanceof String name) {
            ScheduleRegistry.cancel(name);
            return;
        }
        throw new ScriptError("cancel schedule expects a schedule handle or name, got: "
                + Values.displayString(value));
    }
}
