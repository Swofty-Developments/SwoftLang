package net.swofty.nativebridge.execution.commands.displays;

import net.swofty.displays.SwoftDisplay;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;

/**
 * hide display &lt;display&gt; [from &lt;viewer|all&gt;] (design 6B).
 */
public class HideDisplayStatement extends AbstractAstNode implements Statement {
    private final Expression display;
    private final Expression viewer;

    public HideDisplayStatement(Expression display, Expression viewer) {
        this.display = display;
        this.viewer = viewer;
    }

    @Override
    public void execute(ExecutionContext context) {
        SwoftDisplay target = ShowDisplayStatement.requireDisplay(
                context.evaluate(display), "hide display");
        Object who = viewer != null ? context.evaluate(viewer) : "all";
        if (NoneValue.isNone(who) || "all".equals(who)) {
            target.hideAll();
            return;
        }
        if (who instanceof Iterable<?> viewers) {
            for (Object each : viewers) {
                target.hide(context.requirePlayer(each, "hide display"));
            }
            return;
        }
        target.hide(context.requirePlayer(who, "hide display"));
    }
}
