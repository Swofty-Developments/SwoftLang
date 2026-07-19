package net.swofty.mobs;

import net.swofty.entities.EntityTagsView;
import net.swofty.props.NestedValueView;
import net.swofty.props.NoneValue;

/**
 * The {@code mob.tags} view for a scripted mob (W-viewers feature 2). It
 * overlays the mob's LIVE declared typed-tag store on top of the freeform NBT
 * {@link EntityTagsView} that every entity inherits:
 *
 * <ul>
 *   <li>A declared tag key (from the mob's {@code tags { ... }} block) reads and
 *       writes the live in-memory value. A {@code map<Player,Integer>} tag is a
 *       real {@link net.swofty.runtime.MapValue}, so {@code mob.tags.hits[p]}
 *       and {@code set mob.tags.hits[p] to n} operate on the one live map with
 *       no NBT round-trip.</li>
 *   <li>Any other (undeclared) key falls through to the freeform NBT store,
 *       exactly as before, so {@code mob.tags.anykey} still works and flushes
 *       back onto the entity's TagHandler.</li>
 * </ul>
 *
 * <p>Registered as a {@code passThroughHop} on {@link SwoftMob} (more specific
 * than the {@code Entity} row, so it wins the property-registry class walk).
 * Writes into freeform keys rebuild the underlying {@link EntityTagsView} and
 * are flushed by {@link #flush()} from the hop's wither; writes into live keys
 * mutate the store in place.
 */
public final class MobTagsView implements NestedValueView {
    private final SwoftMob mob;
    private final EntityTagsView freeform;

    private MobTagsView(SwoftMob mob, EntityTagsView freeform) {
        this.mob = mob;
        this.freeform = freeform;
    }

    public static MobTagsView of(SwoftMob mob) {
        return new MobTagsView(mob, EntityTagsView.of(mob));
    }

    @Override
    public boolean has(String key) {
        return mob.hasLiveTag(key) || freeform.has(key);
    }

    @Override
    public Object read(String key) {
        if (mob.hasLiveTag(key)) {
            Object value = mob.liveTag(key);
            return value == null ? NoneValue.INSTANCE : value;
        }
        return freeform.read(key);
    }

    @Override
    public Object withChild(String key, Object child) {
        if (mob.hasLiveTag(key)) {
            // a declared typed/value tag: mutate the live store in place. The
            // freeform tree is unchanged, so this same view is still valid.
            mob.liveTags().put(key, NoneValue.isNone(child) ? NoneValue.INSTANCE : child);
            return this;
        }
        Object updated = freeform.withChild(key, child);
        return new MobTagsView(mob, (EntityTagsView) updated);
    }

    @Override
    public NestedValueView emptyChild() {
        return freeform.emptyChild();
    }

    /** Flush the freeform NBT half back onto the entity (live half is in place). */
    public SwoftMob flush() {
        freeform.applyToEntity();
        return mob;
    }

    @Override
    public String toString() {
        return "mob.tags " + mob.liveTags() + " + " + freeform;
    }
}
