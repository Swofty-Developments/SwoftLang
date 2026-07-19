package net.swofty.nativebridge.execution.commands.worlds;

import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;
import net.swofty.worlds.SwoftWorldLoader;

/**
 * Shared argument plumbing for the world statement nodes (design 6B/6D).
 */
final class WorldStatements {
    private WorldStatements() {
    }

    static String name(ExecutionContext context, Expression expression, String what) {
        return (String) Coercions.toStringValue(context.evaluate(expression));
    }

    static SwoftWorldLoader loader(ExecutionContext context, Expression expression,
            String what) {
        Object value = context.evaluate(expression);
        if (value instanceof SwoftWorldLoader loader) {
            return loader;
        }
        throw new ScriptError(what + " expects a world loader "
                + "(anvil_loader/polar_loader/polar_storage_loader), got: "
                + Values.displayString(value));
    }
}
