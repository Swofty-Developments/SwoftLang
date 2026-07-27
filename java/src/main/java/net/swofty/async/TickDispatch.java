package net.swofty.async;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.function.Supplier;

import net.minestom.server.MinecraftServer;
import net.minestom.server.thread.TickSchedulerThread;
import net.minestom.server.thread.TickThread;

/**
 * The only bridge from a script task onto the tick thread. It is what the
 * world-access auto-hop and {@code spawn}/{@code async} rely on to run world
 * mutations on the tick: off-thread callers park at most one tick, while
 * tick-thread and tick-scheduler-thread callers pass through (both run inside
 * the tick; parking the scheduler thread on its own scheduleNextTick task would
 * deadlock the server).
 */
public final class TickDispatch {
    private TickDispatch() {
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

    /**
     * Fire-and-forget onto the tick thread: run {@code action} inline when the
     * caller is already inside the tick (so the effect lands in the same tick
     * as whatever triggered it) or when no server is running (harnesses), and
     * otherwise park it on the next tick WITHOUT blocking the caller.
     *
     * <p>{@link #call} is the wrong tool for a reaction — a persistence write on
     * the bus-subscriber thread must not stall waiting for a tick — so this is
     * the entry point for tick-thread work whose result nobody awaits.
     */
    public static void post(Runnable action) {
        Thread current = Thread.currentThread();
        if (current instanceof TickThread || current instanceof TickSchedulerThread
                || !serverRunning()) {
            action.run();
            return;
        }
        MinecraftServer.getSchedulerManager().scheduleNextTick(action);
    }

    private static boolean serverRunning() {
        try {
            return MinecraftServer.process() != null && MinecraftServer.isStarted();
        } catch (Throwable t) {
            return false;
        }
    }
}
