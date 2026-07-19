package net.swofty.nativebridge.execution.commands.sched;

import java.util.Map;

import net.minestom.server.command.CommandSender;
import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.runtime.EnvSnapshot;
import net.swofty.runtime.ExecutionContext;
import net.swofty.sched.ScheduleRuntime;

/**
 * {@code repeat N times [every dur] { body }} (scheduler v2): the bounded
 * sibling of {@code every}. Starts a fire-and-forget schedule that runs the
 * body exactly N times (spaced by {@code every}, or consecutive ticks by
 * default) then auto-stops. {@code run} and {@code stop} work inside. The
 * body closes over a snapshot of the surrounding environment, so it runs
 * safely alongside the enclosing task.
 */
public class RepeatStatement extends AbstractAstNode implements Statement {
    private final Expression count;
    private final long everyTicks;
    private final ExecuteBlock body;
    private final String name;

    public RepeatStatement(Expression count, long everyTicks, ExecuteBlock body, String name) {
        this.count = count;
        this.everyTicks = everyTicks;
        this.body = body;
        this.name = name;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object value = context.evaluate(count);
        if (!(value instanceof Number number)) {
            throw new ScriptError("repeat count must be a number, got: "
                    + net.swofty.runtime.Values.displayString(value));
        }
        int times = number.intValue();
        Map<String, Object> snapshot = new EnvSnapshot().env(context.getVariables());
        CommandSender sender = context.getSender();
        ScheduleRuntime.startRepeat(times, everyTicks, name, body, sender, snapshot);
    }
}
