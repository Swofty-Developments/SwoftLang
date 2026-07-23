package net.swofty.async;

import java.util.Map;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Supplier;

/**
 * Virtual-thread factory and registry for script tasks. Each async handler,
 * async block, and spawned function call runs as one task.
 */
public final class AsyncRuntime {
    private static final AtomicLong NEXT_ID = new AtomicLong();
    private static final Map<Long, Thread> TASKS = new ConcurrentHashMap<>();
    private static final ThreadFactory FACTORY = Thread.ofVirtual().name("swoft-task-", 0).factory();
    private static final ThreadLocal<Boolean> IN_TASK = ThreadLocal.withInitial(() -> false);

    /**
     * Every pending script future (§1.8.0). {@code spawn}-as-value submits its
     * body here and {@code all of}/{@code any of} track their combined futures,
     * so a reload/shutdown {@link #cancelAll()} can cancel them all — which
     * unwinds any awaiting vthread.
     */
    private static final Set<CompletableFuture<?>> FUTURES = ConcurrentHashMap.newKeySet();

    /**
     * Program generation, bumped on every {@link #cancelAll()} (reload /
     * shutdown teardown). Exposed via {@link #generation()} so a deferred
     * tick-side action can detect that the program was torn down between when it
     * was scheduled and when it runs, and decline to touch the new program.
     */
    private static final AtomicLong GENERATION = new AtomicLong();

    private AsyncRuntime() {
    }

    /** The current program generation (see {@link #GENERATION}). */
    public static long generation() {
        return GENERATION.get();
    }

    /**
     * Whether the current thread is a script task (async context); sync
     * bodies run inline on the caller's thread and answer false
     */
    public static boolean inTask() {
        return IN_TASK.get();
    }

    public static void start(String description, Runnable scriptBody) {
        long id = NEXT_ID.incrementAndGet();
        Thread thread = FACTORY.newThread(() -> {
            IN_TASK.set(true);
            try {
                scriptBody.run();
            } catch (HaltSignal ignored) {
            } catch (Throwable t) {
                System.err.println("Script task '" + description + "' failed: " + t);
                t.printStackTrace();
            } finally {
                TASKS.remove(id);
            }
        });
        TASKS.put(id, thread);
        thread.start();
    }

    /**
     * Run a script body as a task ON the current thread (api handlers:
     * the serving virtual thread IS the task, so the caller can observe
     * the result synchronously). The async-context flag is set for the
     * duration; nesting is a no-op passthrough.
     */
    public static void runInline(String description, Runnable scriptBody) {
        if (IN_TASK.get()) {
            scriptBody.run();
            return;
        }
        IN_TASK.set(true);
        try {
            scriptBody.run();
        } catch (HaltSignal ignored) {
        } finally {
            IN_TASK.set(false);
        }
    }

    /**
     * Submit an async body on a virtual thread and hand back the future it
     * completes (§1.8.0 {@code spawn}-as-value). The body runs in async
     * context ({@link #inTask()} is true), so it may {@code wait}/{@code await}
     * freely. Normal return completes the future with the payload; a
     * {@link HaltSignal} (interrupt / teardown) cancels it; any other throwable
     * completes it exceptionally so a downstream {@code await} re-raises it. The
     * future is tracked for {@link #cancelAll()} until it settles.
     */
    public static CompletableFuture<Object> supply(String description, Supplier<Object> scriptBody) {
        CompletableFuture<Object> future = new CompletableFuture<>();
        FUTURES.add(future);
        future.whenComplete((r, t) -> FUTURES.remove(future));
        long id = NEXT_ID.incrementAndGet();
        Thread thread = FACTORY.newThread(() -> {
            IN_TASK.set(true);
            try {
                future.complete(scriptBody.get());
            } catch (HaltSignal ignored) {
                future.cancel(false);
            } catch (Throwable t) {
                future.completeExceptionally(t);
            } finally {
                TASKS.remove(id);
            }
        });
        TASKS.put(id, thread);
        thread.start();
        return future;
    }

    /**
     * Track an externally-derived future (an {@code all of}/{@code any of}
     * combinator) so {@link #cancelAll()} reaches it too. Removed when it
     * settles.
     */
    public static <T> CompletableFuture<T> track(CompletableFuture<T> future) {
        FUTURES.add(future);
        future.whenComplete((r, t) -> FUTURES.remove(future));
        return future;
    }

    /**
     * Interrupt every live task and cancel every pending future (script reload
     * / server shutdown), then advance the program generation so any tick-side
     * future continuation that had already been scheduled refuses to fire.
     */
    public static void cancelAll() {
        GENERATION.incrementAndGet();
        for (CompletableFuture<?> future : FUTURES) {
            future.cancel(true);
        }
        TASKS.values().forEach(Thread::interrupt);
    }

    /**
     * Wait for all live tasks to finish; used by the headless harness.
     * @return true if every task completed before the timeout
     */
    public static boolean awaitAll(long timeoutMillis) {
        long deadline = System.currentTimeMillis() + timeoutMillis;
        while (!TASKS.isEmpty()) {
            long remaining = deadline - System.currentTimeMillis();
            if (remaining <= 0) {
                return TASKS.isEmpty();
            }
            for (Thread thread : TASKS.values()) {
                remaining = deadline - System.currentTimeMillis();
                if (remaining <= 0) {
                    break;
                }
                try {
                    thread.join(remaining);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    return TASKS.isEmpty();
                }
            }
        }
        return true;
    }

    public static int taskCount() {
        return TASKS.size();
    }
}
