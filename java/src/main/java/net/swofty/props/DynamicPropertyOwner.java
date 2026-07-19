package net.swofty.props;

/**
 * A script value whose property set is resolved at runtime instead of
 * through static PropertyRegistry rows. This exists for exactly one
 * family of values: generic event wrappers, whose property tables come
 * from the generated Minestom event catalog (phase 7). PathResolver
 * consults this interface before the registry; writes anchor on the
 * dynamic owner like they do on plain maps.
 */
public interface DynamicPropertyOwner {

    /** True when the owner exposes the named property (read or write). */
    boolean hasDynamicProperty(String name);

    /**
     * Read a property. Throws ScriptError (with the given position) on
     * unknown names; returns null or NoneValue for absent values.
     */
    Object getDynamicProperty(String name, int line, int col);

    /**
     * Write a property, applying the owner's coercions. Throws
     * ScriptError on unknown or read-only names.
     */
    void setDynamicProperty(String name, Object value, int line, int col);
}
