package net.swofty.nativebridge.execution.commands.holograms;

import net.swofty.holograms.HologramRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/** {@code hide hologram "name" from <player|all>} (first-class GROUP D). */
public class HideHologramStatement extends AbstractAstNode implements Statement {
    private final String name;
    private final Expression target;

    public HideHologramStatement(String name, Expression target) {
        this.name = name;
        this.target = target;
    }

    @Override
    public void execute(ExecutionContext context) {
        HologramRuntime.hide(name, context.evaluate(target));
    }
}
