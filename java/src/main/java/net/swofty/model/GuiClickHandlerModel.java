package net.swofty.model;

import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * on_click(filter) { ... } — filter is left|right|shift_left|shift_right|
 * middle|double|any
 */
public record GuiClickHandlerModel(String filter, ExecuteBlock body) {
}
