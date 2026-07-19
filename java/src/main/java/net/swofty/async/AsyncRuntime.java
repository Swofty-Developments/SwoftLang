package net.swofty.async;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Virtual-thread factory and registry for script tasks. Each async handler,
 * async block, and spawned function call runs as one task.
 */
public final class AsyncRuntime {
    private static final AtomicLong NEXT_ID = new AtomicLong();
    private static final Map<Long, Thread> TASKS = new ConcurrentHashMap<>();
    private static final ThreadFactory FACTORY = Thread.ofVirtual().name("swoft-task-", 0).factory();
    private static final ThreadLocal<Boolean> IN_TASK = ThreadLocal.withInitial(() -> false);

    private AsyncRuntime() {
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
     * Interrupt every live task (script reload / server shutdown)
     */
    public static void cancelAll() {
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
