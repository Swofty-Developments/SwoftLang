package net.swofty.model;

import java.util.List;

import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * paginate template: render/on_click bind item and index
 */
public record GuiPaginateModel(
        Expression source,
        List<Integer> slots,
        ItemSpecModel render,
        ExecuteBlock onClick,
        int prevSlot,
        int nextSlot) {
}
