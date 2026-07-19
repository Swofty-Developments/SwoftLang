package net.swofty.model;

import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * One on_click(&lt;filter&gt;) handler on an item declaration (phase 9). The
 * filter is the click side the handler wants ("left", "right", or "any");
 * the body runs with player and item bound when a matching interaction
 * fires, dispatched from the same PlayerUseItem path filtered by custom_id.
 * Emitted in the same shape as gui slot click handlers.
 */
public record ItemClickHandlerModel(String filter, ExecuteBlock body) {
}
