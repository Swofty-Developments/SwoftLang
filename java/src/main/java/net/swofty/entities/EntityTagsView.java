package net.swofty.entities;

import java.util.LinkedHashMap;
import java.util.Map;

import net.kyori.adventure.nbt.BinaryTag;
import net.kyori.adventure.nbt.CompoundBinaryTag;
import net.minestom.server.entity.Entity;
import net.minestom.server.tag.Tag;
import net.swofty.items.NbtCodec;
import net.swofty.items.NbtCompoundView;
import net.swofty.props.NestedValueView;
import net.swofty.props.NoneValue;

/**
 * The root script view over an entity's freeform nested tags: entity.tags.key,
 * mob.tags.meta.level, etc. Mirrors {@link net.swofty.items.ItemTagsView} but
 * over a MUTABLE Entity (mobs, players, projectiles, plain entities — anything
 * Taggable). All script tags live under one namespaced NBT sub-compound
 * ("swoft_tags") on the entity's TagHandler, so they never collide with
 * Minestom's own entity tags. Reading an absent key yields none, so
 * {@code entity.tags.x otherwise ...} and {@code exists} integrate for free;
 * writes copy-rebuild the tree and flush back onto the entity in place through
 * the entity.tags pass-through hop.
 */
public final class EntityTagsView implements NestedValueView {
    /** Namespaced sub-compound holding every script tag for an entity. */
    private static final Tag<BinaryTag> ENTITY_TAGS = Tag.NBT("swoft_tags");

    private final Entity entity;
    private final Map<String, Object> tree;

    private EntityTagsView(Entity entity, Map<String, Object> tree) {
        this.entity = entity;
        this.tree = tree;
    }

    public static EntityTagsView of(Entity entity) {
        return new EntityTagsView(entity, read(entity));
    }

    private static Map<String, Object> read(Entity entity) {
        BinaryTag raw = entity.getTag(ENTITY_TAGS);
        if (raw instanceof CompoundBinaryTag compound) {
            return NbtCodec.fromCompound(compound);
        }
        return new LinkedHashMap<>();
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
    public EntityTagsView withChild(String key, Object child) {
        Map<String, Object> next = new LinkedHashMap<>(tree);
        if (NoneValue.isNone(child)) {
            next.remove(key);
        } else {
            next.put(key, NbtCompoundView.TagValues.raw(child));
        }
        return new EntityTagsView(entity, next);
    }

    @Override
    public NestedValueView emptyChild() {
        return new NbtCompoundView(new LinkedHashMap<>());
    }

    /** Flush this view's tree back onto the entity's TagHandler in place. */
    public Entity applyToEntity() {
        entity.setTag(ENTITY_TAGS, NbtCodec.toCompound(tree));
        return entity;
    }

    @Override
    public String toString() {
        return "tags " + tree;
    }
}
