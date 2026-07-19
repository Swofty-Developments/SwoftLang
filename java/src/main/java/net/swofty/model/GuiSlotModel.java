package net.swofty.model;

import java.util.List;

import net.swofty.nativebridge.representation.ExecuteBlock;

public record GuiSlotModel(
        List<Integer> slots,
        ItemSpecModel item,
        List<GuiClickHandlerModel> clickHandlers,
        Integer refreshTicks) {

    public ExecuteBlock handlerFor(String filter) {
        for (GuiClickHandlerModel handler : clickHandlers) {
            if (handler.filter().equals(filter)) {
                return handler.body();
            }
        }
        return null;
    }
}
