package net.swofty.items;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import net.swofty.props.NestedValueView;
import net.swofty.props.NoneValue;

/**
 * An immutable view over one nested tag compound (phase 9). Reached by
 * traversing item.tags.&lt;path&gt; into a Map value; deeper keys read the same
 * way and writes copy-rebuild upward so the whole tree flushes back onto
 * the ItemStack through the item.tags hop. Lists read as plain script
 * lists; compounds read as further NbtCompoundViews.
 */
public final class NbtCompoundView implements NestedValueView {
    private final Map<String, Object> map;

    public NbtCompoundView(Map<String, Object> map) {
        this.map = map;
    }

    /** The raw nested map (used when a parent folds this child back in). */
    public Map<String, Object> rawMap() {
        return map;
    }

    @Override
    public boolean has(String key) {
        return map.containsKey(key);
    }

    @Override
    public Object read(String key) {
        Object value = map.get(key);
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
    public Object withChild(String key, Object child) {
        Map<String, Object> next = new LinkedHashMap<>(map);
        if (NoneValue.isNone(child)) {
            next.remove(key);
        } else {
            next.put(key, TagValues.raw(child));
        }
        return new NbtCompoundView(next);
    }

    @Override
    public NestedValueView emptyChild() {
        return new NbtCompoundView(new LinkedHashMap<>());
    }

    @Override
    public String toString() {
        return map.toString();
    }

    /** Shared child-folding helpers for the nested tag views. */
    public static final class TagValues {
        private TagValues() {
        }

        /** Unwrap nested views back into raw Map/List/scalar data. */
        public static Object raw(Object value) {
            if (value instanceof NbtCompoundView view) {
                return view.rawMap();
            }
            if (value instanceof ItemTagsView tags) {
                return tags.tree();
            }
            if (value instanceof net.swofty.entities.EntityTagsView tags) {
                return tags.tree();
            }
            if (value instanceof List<?> list) {
                java.util.List<Object> copy = new java.util.ArrayList<>();
                for (Object element : list) {
                    copy.add(raw(element));
                }
                return copy;
            }
            return value;
        }
    }
}
