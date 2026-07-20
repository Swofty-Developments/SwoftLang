package net.swofty.model;

import java.util.Map;

/**
 * A {@code placement_rule for "id" { ... }} declaration (W-blocks): a native
 * {@link net.minestom.server.instance.block.rule.BlockPlacementRule} routed
 * through the runtime. {@code id} is the target block's namespaced id;
 * {@code selfReplaceable} backs {@code isSelfReplaceable}; {@code callbacks}
 * maps {@code on_place} / {@code on_update} to their Block-returning bodies.
 */
public record PlacementRuleModel(String id, boolean selfReplaceable,
        Map<String, BlockCallbackModel> callbacks, int line, int col) {

    public BlockCallbackModel callback(String name) {
        return callbacks.get(name);
    }
}
