package net.swofty.async;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.PriorityQueue;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import net.minestom.server.MinecraftServer;
import net.minestom.server.timer.ExecutionType;
import net.minestom.server.timer.TaskSchedule;

/**
 * Tick-aligned waits. A single TICK_END task drains due waiters each tick;
 * parked virtual threads resume on their carrier, never the tick thread.
 */
public final class TickClock {
    private record Waiter(long targetTick, CompletableFuture<Void> future) {
    }

    private static final Object LOCK = new Object();
    private static final PriorityQueue<Waiter> WAITERS =
            new PriorityQueue<>(Comparator.comparingLong(Waiter::targetTick));
    private static long currentTick = 0;
    private static volatile boolean running = false;

    private TickClock() {
    }

    /**
     * Start the tick-end drain task; call once after MinecraftServer.init()
     */
    public static void init() {
        if (running) {
            return;
        }
        running = true;
        MinecraftServer.getSchedulerManager()
                .buildTask(TickClock::drain)
                .repeat(TaskSchedule.tick(1))
                .executionType(ExecutionType.TICK_END)
                .schedule();
    }

    public static CompletableFuture<Void> after(long ticks) {
        if (ticks <= 0) {
            return CompletableFuture.completedFuture(null);
        }
        if (!running) {
            // Serverless (harness): approximate one tick as 50ms
            CompletableFuture<Void> future = new CompletableFuture<>();
            CompletableFuture.delayedExecutor(ticks * 50L, TimeUnit.MILLISECONDS)
                    .execute(() -> future.complete(null));
            return future;
        }
        CompletableFuture<Void> future = new CompletableFuture<>();
        synchronized (LOCK) {
            WAITERS.add(new Waiter(currentTick + ticks, future));
        }
        return future;
    }

    private static void drain() {
        List<CompletableFuture<Void>> due = new ArrayList<>();
        synchronized (LOCK) {
            currentTick++;
            while (!WAITERS.isEmpty() && WAITERS.peek().targetTick() <= currentTick) {
                due.add(WAITERS.poll().future());
            }
        }
        for (CompletableFuture<Void> future : due) {
            future.complete(null);
        }
    }
}
