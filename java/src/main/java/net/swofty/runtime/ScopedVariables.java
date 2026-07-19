package net.swofty.runtime;

import java.util.AbstractMap;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * Variable environment layered over a captured map: parameters (and any new
 * bindings) live in a local layer, while names already bound in the captured
 * environment read and write straight through to it. This is what makes
 * closure mutation visible both ways.
 *
 * <p>Two users: lambda invocations (captured = the defining environment,
 * {@code module == null}) and module-scoped execution (captured = the owning
 * module's variable environment, {@code module} = its name). The module form
 * is shared global runtime state, so task snapshots keep the captured map
 * live instead of copying it.
 */
public class ScopedVariables extends AbstractMap<String, Object> {
    private final Map<String, Object> captured;
    private final Map<String, Object> locals = new HashMap<>();
    private final String module;

    public ScopedVariables(Map<String, Object> captured) {
        this(captured, null);
    }

    public ScopedVariables(Map<String, Object> captured, String module) {
        this.captured = captured;
        this.module = module;
    }

    /**
     * The module whose variable environment backs this scope, or null for a
     * plain lambda scope
     */
    public String moduleName() {
        return module;
    }

    /**
     * The captured base map (a module's variable environment for module
     * scopes)
     */
    public Map<String, Object> capturedMap() {
        return captured;
    }

    /**
     * The local (shadowing) layer; exposed for task snapshots
     */
    public Map<String, Object> localsMap() {
        return locals;
    }

    /**
     * Bind a name in the local layer, shadowing any captured binding
     */
    public void declareLocal(String name, Object value) {
        locals.put(name, value);
    }

    @Override
    public Object get(Object key) {
        return locals.containsKey(key) ? locals.get(key) : captured.get(key);
    }

    @Override
    public boolean containsKey(Object key) {
        return locals.containsKey(key) || captured.containsKey(key);
    }

    @Override
    public Object put(String key, Object value) {
        if (value == null) {
            // module environments are concurrent maps (no nulls); readers
            // coerce null to none anyway, so store the marker directly
            value = net.swofty.props.NoneValue.INSTANCE;
        }
        if (!locals.containsKey(key) && captured.containsKey(key)) {
            return captured.put(key, value);
        }
        return locals.put(key, value);
    }

    @Override
    public Object remove(Object key) {
        if (!locals.containsKey(key) && captured.containsKey(key)) {
            return captured.remove(key);
        }
        return locals.remove(key);
    }

    @Override
    public Set<Entry<String, Object>> entrySet() {
        Map<String, Object> merged = new HashMap<>(captured);
        merged.putAll(locals);
        return merged.entrySet();
    }
}
