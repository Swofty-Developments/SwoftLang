package net.swofty.model;

import java.util.Map;

/**
 * A {@code block_handler "id" { ... }} declaration (W-blocks): a first-class
 * {@link net.minestom.server.instance.block.BlockHandler} routed through the
 * runtime. {@code id} is the target block's namespaced id; {@code callbacks}
 * maps callback name ({@code on_place}/{@code on_destroy}/{@code on_interact}/
 * {@code on_touch}/{@code tick}) to its body. Presence of a {@code tick}
 * callback makes the handler tickable.
 */
public record BlockHandlerModel(String id, Map<String, BlockCallbackModel> callbacks,
        int line, int col) {

    public BlockCallbackModel callback(String name) {
        return callbacks.get(name);
    }
}
