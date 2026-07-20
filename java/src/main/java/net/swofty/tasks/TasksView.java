package net.swofty.tasks;

import net.swofty.ScriptError;
import net.swofty.props.NestedValueView;
import net.swofty.props.NoneValue;

/**
 * The read-side view over an owner's task registry: backs a plain
 * {@code <obj>.tasks.<id>} expression, which resolves to {@code optional<Schedule>}
 * (the live handle, or {@code none} when no such task is running). Mirrors the
 * {@code .tags} pass-through hop, but reads defer to {@link TaskRegistry} keyed
 * by owner identity rather than to NBT.
 *
 * <p>Reads only: associating a task goes through the dedicated {@code set
 * <obj>.tasks.<id> to schedule ...} statement (not the generic property-write
 * path), so {@link #withChild} rejects assignment with a helpful message.
 */
public final class TasksView implements NestedValueView {
    private final Object owner;

    public TasksView(Object owner) {
        this.owner = owner;
    }

    @Override
    public boolean has(String id) {
        return TaskRegistry.get(owner, id) != null;
    }

    @Override
    public Object read(String id) {
        Object handle = TaskRegistry.get(owner, id);
        return handle == null ? NoneValue.INSTANCE : handle;
    }

    @Override
    public Object withChild(String id, Object child) {
        throw new ScriptError("cannot assign <obj>.tasks." + id
                + " through a property write; use 'set <obj>.tasks." + id
                + " to schedule ...'");
    }

    @Override
    public NestedValueView emptyChild() {
        throw new ScriptError("the .tasks namespace has no nested compounds");
    }

    @Override
    public String toString() {
        return "tasks(" + owner + ")";
    }
}
