package net.swofty.items;

import net.minestom.server.item.ItemStack;
import net.swofty.props.NoneValue;
import net.swofty.props.PropertyDef;
import net.swofty.props.PropertyRegistry;

/**
 * The item property namespace (phase 9): item.custom_id (read-only) and
 * item.tags.&lt;path...&gt; — arbitrary nested NBT with get/set/delete. tags is
 * a pass-through hop returning an {@link ItemTagsView}; deeper keys resolve
 * dynamically through the nested-value copy-hop path, so no per-key rows
 * need registering and any depth works on any ItemStack.
 */
public final class ItemProperties {
    private static boolean registered = false;

    private ItemProperties() {
    }

    public static synchronized void ensureRegistered() {
        if (registered) {
            return;
        }
        registered = true;

        PropertyRegistry.register(PropertyDef.readOnly("custom_id", ItemStack.class,
                stack -> {
                    String id = ItemRegistry.customId(stack);
                    return id != null ? id : NoneValue.INSTANCE;
                }));

        // tags is a pass-through hop: item.tags.<path> writes rebuild a new
        // re-rendered ItemStack, but item.tags itself is not assignable
        PropertyRegistry.register(PropertyDef.passThroughHop("tags", ItemStack.class,
                ItemTagsView::of,
                (stack, value) -> ((ItemTagsView) value).applyToStack(),
                value -> {
                    throw new net.swofty.ScriptError(
                            "item.tags is not directly assignable - set item.tags.<key> instead");
                }));
    }
}
