package net.swofty.props;

/**
 * An immutable nested value whose keys are resolved at runtime and whose
 * writes propagate by copy rather than in place (phase 9). Unlike
 * {@link DynamicPropertyOwner} — which anchors writes on itself — a
 * NestedValueView is treated by {@link PathResolver} as a chain of copy
 * hops: a write to any depth rebuilds every enclosing view and finally
 * rebinds the root variable, so an ItemStack-backed tag tree flushes back
 * through the item.tags hop exactly like the phase-5 rebind path. This
 * powers item.tags.&lt;path...&gt; get/set/delete over nested NBT.
 */
public interface NestedValueView {

    /** True when this level contains the key (read or write target). */
    boolean has(String key);

    /**
     * Read one key: a scalar, a list, another NestedValueView for a nested
     * compound, or {@link NoneValue#INSTANCE} when absent.
     */
    Object read(String key);

    /**
     * Copy-with: return a new view of the same family with the key set to
     * the child value, or removed when the child is none. A child that is
     * itself a NestedValueView is folded back into raw nested data.
     */
    Object withChild(String key, Object child);

    /**
     * A fresh empty nested compound of this family, used to auto-vivify a
     * missing intermediate on a deep write (item.tags.a.b = v with a absent):
     * {@link PathResolver} substitutes this for the none it would otherwise
     * walk into, so the copy-hop wither chain rebuilds the whole compound
     * instead of aborting. Stays a NestedValueView so deeper hops keep
     * copy-rebuilding.
     */
    NestedValueView emptyChild();
}
