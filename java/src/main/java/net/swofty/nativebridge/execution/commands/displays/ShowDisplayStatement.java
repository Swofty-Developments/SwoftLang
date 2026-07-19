package net.swofty.nativebridge.execution.commands.displays;

import net.minestom.server.entity.Player;
import net.swofty.ScriptError;
import net.swofty.displays.SwoftDisplay;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * show display &lt;display&gt; [to &lt;viewer|all&gt;] (design 6B): per-viewer
 * visibility over Entity addViewer control. No viewer / "all" restores
 * auto-viewable mode.
 */
public class ShowDisplayStatement extends AbstractAstNode implements Statement {
    private final Expression display;
    private final Expression viewer;

    public ShowDisplayStatement(Expression display, Expression viewer) {
        this.display = display;
        this.viewer = viewer;
    }

    static SwoftDisplay requireDisplay(Object value, String what) {
        if (value instanceof SwoftDisplay display) {
            return display;
        }
        throw new ScriptError(what + " expects a display, got: " + Values.displayString(value));
    }

    @Override
    public void execute(ExecutionContext context) {
        SwoftDisplay target = requireDisplay(context.evaluate(display), "show display");
        Object who = viewer != null ? context.evaluate(viewer) : "all";
        if (NoneValue.isNone(who) || "all".equals(who)) {
            target.showAll();
            return;
        }
        if (who instanceof Iterable<?> viewers) {
            for (Object each : viewers) {
                target.show(context.requirePlayer(each, "show display"));
            }
            return;
        }
        target.show(context.requirePlayer(who, "show display"));
    }
}
