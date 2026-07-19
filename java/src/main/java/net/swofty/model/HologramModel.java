package net.swofty.model;

import java.util.Map;

import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * hologram "name" { ... } declaration (design 6C, first-class). A stack of
 * text-display entities anchored at {@code location}, stacked downward. The
 * {@code lines} body is a restricted statement list (line/blank/if/loop)
 * rendered per cycle; when {@code perViewer} it is re-rendered per viewer
 * through an executor child env with {@code player} bound (same machinery as
 * scoreboards), otherwise once for all viewers.
 *
 * <ul>
 *   <li>{@code location} — required base position expression.</li>
 *   <li>{@code billboard} — center | vertical | horizontal | fixed
 *       (nullable, defaults to center).</li>
 *   <li>{@code scale} — nullable scalar expression, defaults to 1.0.</li>
 *   <li>{@code update} — re-render cadence (TICKS or MANUAL).</li>
 *   <li>{@code perViewer} — true when a line interpolates a player-scoped
 *       path, so each viewer gets a private stack rendered in their env.</li>
 * </ul>
 */
public record HologramModel(
        String name,
        Expression location,
        String billboard,
        Expression scale,
        UpdateCadence update,
        boolean perViewer,
        ExecuteBlock lines,
        Map<String, InlineHandler> handlers) {

    /** Pre-inline-handlers shape, kept for existing call sites/smoke tests. */
    public HologramModel(String name, Expression location, String billboard,
            Expression scale, UpdateCadence update, boolean perViewer,
            ExecuteBlock lines) {
        this(name, location, billboard, scale, update, perViewer, lines, Map.of());
    }

    /** The generic first-class handler for {@code event}, or null. */
    public InlineHandler handler(String event) {
        return handlers == null ? null : handlers.get(event);
    }
}
