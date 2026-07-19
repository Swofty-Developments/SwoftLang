package net.swofty.props;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import net.minestom.server.entity.Player;
import net.swofty.ScriptError;
import net.swofty.async.TickDispatch;
import net.swofty.runtime.MapValue;

/**
 * Shared property-path resolution used by structured prop/set_prop chains AND
 * ${a.b.c} string interpolation. Reads go through the PropertyRegistry
 * whitelist; writes use the anchor+wither algorithm: the deepest settable hop
 * is the anchor, hops past it must be copy hops (withers), and the whole
 * read-withers-set sequence runs inside one TickDispatch.call when any hop
 * carries the TICK policy.
 */
public final class PathResolver {
    private static final boolean REFLECTION_FALLBACK =
            Boolean.getBoolean("swoftlang.reflection");

    private PathResolver() {
    }

    /**
     * Resolve one property hop. Maps act as plain key lookups (arg scopes,
     * GUI state); none propagates; null getter results become none.
     */
    public static Object getProperty(Object owner, String name, int line, int col) {
        if (NoneValue.isNone(owner)) {
            return NoneValue.INSTANCE;
        }
        // W-collections: zero-arg property-form accessors on script maps, lists
        // and strings (size / is_empty / keys / values / first / last / length).
        // These compute a value; they are NOT key lookups (index syntax m[k] is
        // the key-lookup path). Checked before the generic Map branch because a
        // MapValue is itself a Map. keys/values return a fresh list so callers
        // can loop or mutate without touching the backing map.
        if (owner instanceof MapValue mapValue) {
            switch (name) {
                case "size":
                    return mapValue.size();
                case "is_empty":
                    return mapValue.isEmpty();
                case "keys":
                    return new ArrayList<Object>(mapValue.keySet());
                case "values":
                    return new ArrayList<Object>(mapValue.values());
                default:
                    break; // fall through to the generic key-lookup below
            }
        }
        if (owner instanceof List<?> list) {
            switch (name) {
                case "size":
                    return list.size();
                case "is_empty":
                    return list.isEmpty();
                case "first": {
                    if (list.isEmpty()) {
                        return NoneValue.INSTANCE;
                    }
                    Object value = list.get(0);
                    return value == null ? NoneValue.INSTANCE : value;
                }
                case "last": {
                    if (list.isEmpty()) {
                        return NoneValue.INSTANCE;
                    }
                    Object value = list.get(list.size() - 1);
                    return value == null ? NoneValue.INSTANCE : value;
                }
                default:
                    break;
            }
        }
        if (owner instanceof String string && name.equals("length")) {
            return string.length();
        }
        if (owner instanceof Map<?, ?> map) {
            Object value = map.get(name);
            return value == null ? NoneValue.INSTANCE : value;
        }
        if (owner instanceof DynamicPropertyOwner dynamic) {
            Object value = dynamic.getDynamicProperty(name, line, col);
            return value == null ? NoneValue.INSTANCE : value;
        }
        if (owner instanceof NestedValueView nested) {
            Object value = nested.read(name);
            return value == null ? NoneValue.INSTANCE : value;
        }
        Optional<PropertyDef> def = PropertyRegistry.lookup(owner.getClass(), name);
        if (def.isPresent()) {
            if (def.get().getter() == null) {
                throw new ScriptError("property '" + name + "' on "
                        + owner.getClass().getSimpleName() + " is write-only", line, col);
            }
            Object value = def.get().getter().apply(owner);
            return value == null ? NoneValue.INSTANCE : value;
        }
        if (REFLECTION_FALLBACK) {
            Object value = reflectGet(owner, name);
            return value == null ? NoneValue.INSTANCE : value;
        }
        throw new ScriptError("unknown property '" + name + "' on "
                + owner.getClass().getSimpleName(), line, col);
    }

    /**
     * Walk a full path from a root value, none-propagating
     */
    public static Object getPath(Object root, List<String> names, int line, int col) {
        Object current = root;
        for (String name : names) {
            current = getProperty(current, name, line, col);
        }
        return current;
    }

    /**
     * Write through a chain rooted at a script variable; the variable slot
     * itself is the fallback anchor
     */
    public static void assignVariablePath(Map<String, Object> variables, String rootName,
                                          List<String> names, Object value, int line, int col) {
        Object root = variables.containsKey(rootName) ? variables.get(rootName)
                : "args".equals(rootName) ? variables
                : NoneValue.INSTANCE;
        if (NoneValue.isNone(root)) {
            System.err.println("Error: Cannot set property on non-existent object: " + rootName);
            return;
        }
        write(variables, rootName, root, names, value, line, col);
    }

    /**
     * Write through a chain rooted at an already-evaluated object (no
     * variable-slot anchor available)
     */
    public static void assignObjectPath(Object root, List<String> names, Object value,
                                        int line, int col) {
        if (NoneValue.isNone(root)) {
            throw new ScriptError("cannot set property '" + names.get(names.size() - 1)
                    + "' on none", line, col);
        }
        write(null, null, root, names, value, line, col);
    }

    private static void write(Map<String, Object> variables, String rootName, Object root,
                              List<String> names, Object value, int line, int col) {
        Resolved probe = resolve(root, names, line, col);
        if (probe.anyTick) {
            TickDispatch.call(() -> {
                commit(variables, rootName, resolve(freshRoot(variables, rootName, root), names, line, col),
                        names, value, line, col);
                return null;
            });
        } else {
            commit(variables, rootName, probe, names, value, line, col);
        }
    }

    private static Object freshRoot(Map<String, Object> variables, String rootName, Object fallback) {
        if (variables == null || rootName == null) {
            return fallback;
        }
        Object value = variables.containsKey(rootName) ? variables.get(rootName)
                : "args".equals(rootName) ? variables : fallback;
        return NoneValue.isNone(value) ? fallback : value;
    }

    private record Resolved(Object[] owners, PropertyDef[] defs, boolean anyTick) {
    }

    private static Resolved resolve(Object root, List<String> names, int line, int col) {
        int count = names.size();
        Object[] owners = new Object[count];
        PropertyDef[] defs = new PropertyDef[count];
        boolean anyTick = false;

        Object owner = root;
        for (int i = 0; i < count; i++) {
            String name = names.get(i);
            if (NoneValue.isNone(owner)) {
                throw new ScriptError("cannot resolve property '" + name
                        + "': value before it is none", line, col);
            }
            owners[i] = owner;
            if (owner instanceof NestedValueView) {
                // a copy hop: never the anchor, always rebuilds upward so
                // the whole tree flushes back through the root variable
                final String key = name;
                defs[i] = new PropertyDef(key, owner.getClass(),
                        o -> ((NestedValueView) o).read(key),
                        null,
                        (o, v) -> ((NestedValueView) o).withChild(key, v),
                        null, ThreadPolicy.ANY, false);
            } else if (owner instanceof Map<?, ?> || owner instanceof DynamicPropertyOwner) {
                defs[i] = null;
            } else {
                Class<?> ownerClass = owner.getClass();
                defs[i] = PropertyRegistry.lookup(ownerClass, name)
                        .orElseThrow(() -> new ScriptError("unknown property '" + name + "' on "
                                + ownerClass.getSimpleName(), line, col));
                if (defs[i].thread() == ThreadPolicy.TICK) {
                    anyTick = true;
                }
            }
            if (i < count - 1) {
                Object next = getProperty(owner, name, line, col);
                if (NoneValue.isNone(next) && owner instanceof NestedValueView nested) {
                    // auto-vivify a missing intermediate compound so a deep
                    // write into a nested tag tree (item.tags.a.b = v, with 'a'
                    // absent) rebuilds the chain through the copy-hop withers
                    // instead of aborting on the none. Only nested (copy-hop)
                    // owners vivify; a none under a normal owner still throws.
                    next = nested.emptyChild();
                }
                owner = next;
            }
        }
        return new Resolved(owners, defs, anyTick);
    }

    private static void commit(Map<String, Object> variables, String rootName, Resolved resolved,
                               List<String> names, Object value, int line, int col) {
        Object[] owners = resolved.owners();
        PropertyDef[] defs = resolved.defs();
        int count = names.size();

        int anchor = -1;
        for (int i = count - 1; i >= 0; i--) {
            if (defs[i] == null || defs[i].isSettable()) {
                anchor = i;
                break;
            }
        }
        if (anchor == -1 && variables == null) {
            throw new ScriptError("cannot assign '" + String.join(".", names)
                    + "': no writable property in the chain", line, col);
        }
        for (int i = anchor + 1; i < count; i++) {
            if (defs[i] == null || !defs[i].isCopyHop()) {
                throw new ScriptError("property '" + names.get(i) + "' on "
                        + owners[i].getClass().getSimpleName() + " is read-only", line, col);
            }
        }

        PropertyDef last = defs[count - 1];
        Object coerced = value;
        if (last != null && last.coercion() != null) {
            try {
                coerced = last.coercion().apply(value);
            } catch (ScriptError e) {
                throw e.at(line, col);
            }
        }
        for (int i = count - 1; i > anchor; i--) {
            coerced = defs[i].wither().apply(owners[i], coerced);
        }

        if (anchor == -1) {
            variables.put(rootName, coerced);
            return;
        }
        if (defs[anchor] == null) {
            if (owners[anchor] instanceof DynamicPropertyOwner dynamic) {
                dynamic.setDynamicProperty(names.get(anchor), coerced, line, col);
                return;
            }
            @SuppressWarnings("unchecked")
            Map<String, Object> map = (Map<String, Object>) owners[anchor];
            map.put(names.get(anchor), coerced);
            return;
        }
        PropertyDef def = defs[anchor];
        if (anchor < count - 1 && def.coercion() != null) {
            try {
                coerced = def.coercion().apply(coerced);
            } catch (ScriptError e) {
                throw e.at(line, col);
            }
        }
        if (def.thread() == ThreadPolicy.TICK
                && owners[anchor] instanceof Player player && !player.isOnline()) {
            System.err.println("Debug: skipping write to '" + names.get(anchor)
                    + "': player " + player.getUsername() + " is offline");
            return;
        }
        def.setter().accept(owners[anchor], coerced);
    }

    private static Object reflectGet(Object owner, String name) {
        String upper = Character.toUpperCase(name.charAt(0)) + name.substring(1);
        for (String candidate : new String[]{"get" + upper, "is" + upper, name}) {
            try {
                Method method = owner.getClass().getMethod(candidate);
                return method.invoke(owner);
            } catch (Exception ignored) {
            }
        }
        return null;
    }
}
