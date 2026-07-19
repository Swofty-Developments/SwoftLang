package net.swofty.model;

import java.util.List;

import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * editable [slots] { on_change { ... } } — on_change binds slot, old_item,
 * new_item
 */
public record GuiEditableModel(List<Integer> slots, ExecuteBlock onChange) {
}
