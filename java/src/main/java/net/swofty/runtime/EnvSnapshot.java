package net.swofty.runtime;

import java.util.HashMap;
import java.util.IdentityHashMap;
import java.util.Map;

/**
 * Shallow snapshot of variable environments crossing a task boundary
 * (spawn / async block): bindings are copied and objects are shared, except
 * callables, which are rebound over snapshots of their captured environments
 * so writes through them stay inside the task. One instance spans a whole
 * boundary, so callables sharing an environment (or capturing themselves)
 * share its single copy on the task's side.
 */
public final class EnvSnapshot {
    private final Map<Map<String, Object>, Map<String, Object>> copies = new IdentityHashMap<>();

    public Map<String, Object> env(Map<String, Object> variables) {
        Map<String, Object> copy = copies.get(variables);
        if (copy != null) {
            return copy;
        }
        if (variables instanceof ScopedVariables scoped && scoped.moduleName() != null) {
            // module-scoped environment: the module's variable map is shared
            // global runtime state, so the task keeps writing through to it;
            // only the local (per-invocation) layer is snapshotted
            ScopedVariables moduleCopy =
                    new ScopedVariables(scoped.capturedMap(), scoped.moduleName());
            copies.put(variables, moduleCopy);
            for (Map.Entry<String, Object> entry : scoped.localsMap().entrySet()) {
                moduleCopy.declareLocal(entry.getKey(), value(entry.getValue()));
            }
            return moduleCopy;
        }
        copy = new HashMap<>(variables);
        copies.put(variables, copy);
        for (Map.Entry<String, Object> entry : copy.entrySet()) {
            entry.setValue(value(entry.getValue()));
        }
        return copy;
    }

    public Object value(Object value) {
        if (value instanceof SwoftCallable callable) {
            return callable(callable);
        }
        return value;
    }

    public SwoftCallable callable(SwoftCallable callable) {
        return new SwoftCallable(callable.params(), callable.body(),
                env(callable.captured()), callable.async(), callable.module());
    }
}
