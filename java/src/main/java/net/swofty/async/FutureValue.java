package net.swofty.async;

import java.util.concurrent.CompletableFuture;

/**
 * The runtime value backing a script {@code Future<T>} (§1.8.0 futures). It
 * wraps a {@link CompletableFuture} completed by the virtual thread running
 * the spawned async body: normal completion carries the payload, exceptional
 * completion carries the {@code ScriptError} the body raised, and cancellation
 * (reload/shutdown teardown via {@link AsyncRuntime#cancelAll()}) marks the
 * future cancelled.
 *
 * <p>{@code await} reads it with {@code cf().get()}, {@code when ... is ready}
 * registers a {@code whenComplete} continuation, and {@code all of}/{@code any
 * of} combine several of them.
 */
public final class FutureValue {
    private final CompletableFuture<Object> cf;

    public FutureValue(CompletableFuture<Object> cf) {
        this.cf = cf;
    }

    /** The underlying completable future (payload is the script T value). */
    public CompletableFuture<Object> cf() {
        return cf;
    }

    public String displayString() {
        return toString();
    }

    @Override
    public String toString() {
        if (cf.isCancelled()) {
            return "<future cancelled>";
        }
        if (cf.isCompletedExceptionally()) {
            return "<future failed>";
        }
        return cf.isDone() ? "<future done>" : "<future pending>";
    }
}
