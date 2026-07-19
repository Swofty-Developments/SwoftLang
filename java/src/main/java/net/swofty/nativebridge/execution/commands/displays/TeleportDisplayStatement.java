package net.swofty.nativebridge.execution.commands.displays;

import net.minestom.server.coordinate.Pos;
import net.swofty.ScriptError;
import net.swofty.displays.SwoftDisplay;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * teleport display &lt;display&gt; to &lt;location&gt; (design 6B).
 */
public class TeleportDisplayStatement extends AbstractAstNode implements Statement {
    private final Expression display;
    private final Expression location;

    public TeleportDisplayStatement(Expression display, Expression location) {
        this.display = display;
        this.location = location;
    }

    @Override
    public void execute(ExecutionContext context) {
        SwoftDisplay target = ShowDisplayStatement.requireDisplay(
                context.evaluate(display), "teleport display");
        Object where = context.evaluate(location);
        if (!(where instanceof Pos pos)) {
            throw new ScriptError("teleport display expects a location, got: "
                    + Values.displayString(where));
        }
        target.teleport(pos);
    }
}
