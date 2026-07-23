package net.swofty.async;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.function.Supplier;

import net.minestom.server.MinecraftServer;
import net.minestom.server.thread.TickSchedulerThread;
import net.minestom.server.thread.TickThread;

/**
 * The only bridge from a script task onto the tick thread. Tick-thread and
 * tick-scheduler-thread callers pass through (both run inside the tick;
 * parking the scheduler thread on its own scheduleNextTick task would
 * deadlock the server); other threads park at most one tick.
 */
public final class TickDispatch {
    private TickDispatch() {
    }

    /**
     * Schedule {@code action} to run on the tick thread on the next tick,
     * fire-and-forget (the {@code when ... is ready} continuation lands its
     * body back on the tick thread). Tick-thread callers run it inline; when
     * the server is not running (headless harness) it runs inline too.
     */
    public static void runNextTick(Runnable action) {
        Thread current = Thread.currentThread();
        if (current instanceof TickThread || current instanceof TickSchedulerThread
                || !serverRunning()) {
            action.run();
            return;
        }
        MinecraftServer.getSchedulerManager().scheduleNextTick(action);
    }

    public static <T> T call(Supplier<T> action) {
        Thread current = Thread.currentThread();
        if (current instanceof TickThread || current instanceof TickSchedulerThread) {
            return action.get();
        }
        if (!serverRunning()) {
            return action.get();
        }
        CompletableFuture<T> future = new CompletableFuture<>();
        MinecraftServer.getSchedulerManager().scheduleNextTick(() -> {
            try {
                future.complete(action.get());
            } catch (Throwable t) {
                future.completeExceptionally(t);
            }
        });
        try {
            return future.get();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new HaltSignal();
        } catch (ExecutionException e) {
            Throwable cause = e.getCause();
            if (cause instanceof RuntimeException runtime) {
                throw runtime;
            }
            throw new RuntimeException(cause);
        }
    }

    private static boolean serverRunning() {
        try {
            return MinecraftServer.process() != null && MinecraftServer.isStarted();
        } catch (Throwable t) {
            return false;
        }
    }
}
