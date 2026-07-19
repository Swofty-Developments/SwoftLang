package net.swofty.runtime;

import java.util.List;
import java.util.Map;

import net.swofty.compiler.SwoftFunction;
import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * A first-class function value produced by a lambda expression. Captures the
 * defining environment by reference: the body reads and writes the same
 * variable map it was created in, so mutation is visible both ways.
 *
 * <p>{@code module} is the module scope the lambda was defined in (null for
 * flat scripts). Invocations re-enter that scope so the bundle-tagged body
 * never re-layers a fresh copy of the environment over the module map —
 * writes to captured variables keep landing in the creator's environment.
 */
public record SwoftCallable(List<SwoftFunction.Param> params, ExecuteBlock body,
        Map<String, Object> captured, boolean async, String module) {

    public SwoftCallable(List<SwoftFunction.Param> params, ExecuteBlock body,
            Map<String, Object> captured, boolean async) {
        this(params, body, captured, async,
                captured instanceof ScopedVariables scoped ? scoped.moduleName() : null);
    }

    public String displayString() {
        int count = params.size();
        return "<" + (async ? "async function" : "function")
                + "(" + count + (count == 1 ? " param" : " params") + ")>";
    }

    @Override
    public String toString() {
        return displayString();
    }
}
