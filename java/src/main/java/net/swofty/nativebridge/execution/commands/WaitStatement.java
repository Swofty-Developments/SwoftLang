package net.swofty.nativebridge.execution.commands;

import java.time.Duration;
import java.util.concurrent.ExecutionException;

import net.minestom.server.thread.TickSchedulerThread;
import net.minestom.server.thread.TickThread;
import net.swofty.ScriptError;
import net.swofty.async.HaltSignal;
import net.swofty.async.TickClock;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

public class WaitStatement extends AbstractAstNode implements Statement {
    public enum Unit {
        TICKS,
        SECONDS,
        MILLIS
    }

    private final Expression amount;
    private final Unit unit;

    public WaitStatement(Expression amount, Unit unit) {
        this.amount = amount;
        this.unit = unit;
    }

    public Expression getAmount() {
        return amount;
    }

    public Unit getUnit() {
        return unit;
    }

    /**
     * wait N ticks|seconds|millis — parks the task's virtual thread only
     */
    @Override
    public void execute(ExecutionContext context) {
        Object amountValue = context.evaluate(amount);
        if (!(amountValue instanceof Number)) {
            throw new ScriptError("wait expects a number, got: "
                    + Values.displayString(amountValue));
        }
        if (Thread.currentThread() instanceof TickThread
                || Thread.currentThread() instanceof TickSchedulerThread) {
            throw new IllegalStateException(
                    "wait must not run on a tick thread; the compiler should have rejected this");
        }
        long value = ((Number) amountValue).longValue();
        try {
            switch (unit) {
                case SECONDS -> Thread.sleep(Duration.ofSeconds(value));
                case MILLIS -> Thread.sleep(Duration.ofMillis(value));
                case TICKS -> TickClock.after(value).get();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new HaltSignal();
        } catch (ExecutionException e) {
            throw new RuntimeException(e.getCause());
        }
    }
}
