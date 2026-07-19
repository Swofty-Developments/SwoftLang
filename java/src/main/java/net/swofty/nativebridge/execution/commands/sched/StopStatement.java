package net.swofty.nativebridge.execution.commands.sched;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.sched.ScheduleHandle;
import net.swofty.sched.ScheduleRuntime;

/**
 * {@code stop} (scheduler v2): cancels the enclosing schedule/repeat so it
 * will not fire again after the current run. Legal only inside a scheduled
 * block (the checker enforces that); the handle rides in the block
 * environment under {@link ScheduleRuntime#HANDLE_KEY}, so it is reachable
 * even from a nested {@code async {}} whose env is a snapshot of this one.
 *
 * <p>Distinct from {@code halt}: {@code stop} cancels the repetition, while
 * {@code halt} unwinds the current run. A {@code stop} outside any schedule
 * is a no-op at runtime (defensive; the compiler rejects it).
 */
public class StopStatement extends AbstractAstNode implements Statement {

    @Override
    public void execute(ExecutionContext context) {
        Object handle = context.getVariables().get(ScheduleRuntime.HANDLE_KEY);
        if (handle instanceof ScheduleHandle schedule) {
            schedule.cancel();
        }
    }
}
