package net.swofty.model;

import java.util.List;

import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * The change handler attached to a persistent declaration (design 1.10.0 §4):
 * {@code on_change { }} for a scalar value, {@code on_entry_change { }} for a
 * Map/List (which reacts one ENTRY at a time).
 *
 * <p>{@code binds} is the compiler's list of the bare names the body reads, in
 * binding order — {@code player} / {@code key} for the declaration's own key,
 * {@code key} for the changed entry, plus {@code old}, {@code new} and
 * {@code caused_here}. The runtime pushes exactly those, so what typechecked is
 * what the frame holds.
 */
public record PersistChangeModel(String kind, List<String> binds, ExecuteBlock body,
        int line, int col) {

    /** Whole-value reaction: {@code on_change}. */
    public static final String SCALAR = "on_change";

    /** Per-entry reaction: {@code on_entry_change}. */
    public static final String ENTRY = "on_entry_change";

    /** Whether this handler reacts per ENTRY rather than to the whole value. */
    public boolean isEntry() {
        return ENTRY.equals(kind);
    }

    /** Whether the body binds {@code name}. */
    public boolean bindsName(String name) {
        return binds != null && binds.contains(name);
    }
}
