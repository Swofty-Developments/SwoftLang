package net.swofty.nativebridge.execution.expressions;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.runtime.ExecutionContext;
import net.swofty.sched.ScheduleRuntime;

/**
 * schedule [after &lt;dur&gt;] [every &lt;dur&gt;] { ... } (design 6D): starts a
 * cancellable tick-aligned task and evaluates to its Schedule handle.
 * The async-colored body closes over the surrounding environment
 * (lambda capture semantics: mutation is visible both ways).
 */
public class ScheduleExpression extends AbstractAstNode implements Expression {
    private final long afterTicks;
    private final long everyTicks;
    private final ExecuteBlock body;
    private final String name;

    public ScheduleExpression(long afterTicks, long everyTicks, ExecuteBlock body) {
        this(afterTicks, everyTicks, body, null);
    }

    public ScheduleExpression(long afterTicks, long everyTicks, ExecuteBlock body, String name) {
        this.afterTicks = afterTicks;
        this.everyTicks = everyTicks;
        this.body = body;
        this.name = name;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        return ScheduleRuntime.startExpression(afterTicks, everyTicks, name, body,
                context.getSender(), context.getVariables());
    }
}
