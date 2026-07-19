package net.swofty.sched;

import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * A cancellable schedule value (design 6D / scheduler v2): returned by the
 * schedule expression and held by named/repeat schedules. {@code cancel} (or
 * a {@code stop} statement inside the body) flips the cancel flag; the loop
 * task checks it before its next fire and exits. The run counter is bumped
 * once per fire and bound as {@code run} into the block environment.
 */
public final class ScheduleHandle {
    private final String description;
    private final AtomicBoolean cancelled = new AtomicBoolean(false);
    private final AtomicInteger runs = new AtomicInteger(0);
    private volatile boolean finished = false;
    /** Registered name, or null for an anonymous handle. */
    private volatile String name;

    public ScheduleHandle(String description) {
        this.description = description;
    }

    public String description() {
        return description;
    }

    public String name() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    /** Cancel this schedule: it will not fire again after the current run. */
    public void cancel() {
        cancelled.set(true);
    }

    public boolean isCancelled() {
        return cancelled.get();
    }

    /** Advance and return the 1-based index of the fire about to run. */
    public int nextRun() {
        return runs.incrementAndGet();
    }

    /** Number of times the body has fired so far. */
    public int runCount() {
        return runs.get();
    }

    void markFinished() {
        finished = true;
    }

    /** Live (neither cancelled nor finished) — backs {@code is_running}. */
    public boolean isRunning() {
        return !cancelled.get() && !finished;
    }

    public boolean isActive() {
        return isRunning();
    }

    @Override
    public String toString() {
        return "schedule(" + description + (isRunning() ? "" : ", done") + ")";
    }
}
