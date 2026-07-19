package net.swofty.items;

import java.util.LinkedHashMap;
import java.util.Map;

import net.minestom.server.item.ItemStack;
import net.swofty.props.NestedValueView;
import net.swofty.props.NoneValue;

/**
 * The root script view over an item's freeform nested tags: item.tags.key,
 * item.tags.meta.tier, etc. (phase 9 §2). Works on ANY ItemStack, not only
 * registry items. Immutable: writes copy-rebuild the tree and flush back
 * onto the stack through {@link ItemRegistry#setTags}, re-rendering the
 * display projection for registry items. Reading an absent key yields
 * none, so item.tags.x otherwise ... and exists integrate for free.
 */
public final class ItemTagsView implements NestedValueView {
    private final ItemStack stack;
    private final Map<String, Object> tree;

    private ItemTagsView(ItemStack stack, Map<String, Object> tree) {
        this.stack = stack;
        this.tree = tree;
    }

    public static ItemTagsView of(ItemStack stack) {
        return new ItemTagsView(stack, ItemRegistry.readTags(stack));
    }

    /** The raw nested tree (used when a parent folds this view back in). */
    public Map<String, Object> tree() {
        return tree;
    }

    @Override
    public boolean has(String key) {
        return tree.containsKey(key);
    }

    @Override
    public Object read(String key) {
        Object value = tree.get(key);
        if (value == null) {
            return NoneValue.INSTANCE;
        }
        if (value instanceof Map<?, ?> nested) {
            @SuppressWarnings("unchecked")
            Map<String, Object> typed = (Map<String, Object>) nested;
            return new NbtCompoundView(typed);
        }
        return value;
    }

    @Override
    public ItemTagsView withChild(String key, Object child) {
        Map<String, Object> next = new LinkedHashMap<>(tree);
        if (NoneValue.isNone(child)) {
            next.remove(key);
        } else {
            next.put(key, NbtCompoundView.TagValues.raw(child));
        }
        return new ItemTagsView(stack, next);
    }

    @Override
    public NestedValueView emptyChild() {
        return new NbtCompoundView(new LinkedHashMap<>());
    }

    /** Flush this view back onto its stack, re-rendering the projection. */
    public ItemStack applyToStack() {
        return ItemRegistry.setTags(stack, tree);
    }

    @Override
    public String toString() {
        return "tags " + tree;
    }
}
