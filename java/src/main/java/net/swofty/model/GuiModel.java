package net.swofty.model;

import java.util.List;
import java.util.Map;

import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * gui "name" { ... } declaration; consumed by the GUI runtime
 */
public record GuiModel(
        String name,
        int rows,
        Expression title,
        Map<String, Expression> state,
        Expression fill,
        Expression border,
        List<GuiSlotModel> slots,
        List<GuiEditableModel> editable,
        GuiPaginateModel paginate,
        Integer refreshTicks,
        ExecuteBlock onOpen,
        ExecuteBlock onClose,
        ExecuteBlock onClickFallback) {
}
