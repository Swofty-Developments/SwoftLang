package net.swofty.nativebridge.execution.commands.holograms;

import net.swofty.holograms.HologramRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/** {@code move hologram "name" to <location>} (first-class GROUP D). */
public class MoveHologramStatement extends AbstractAstNode implements Statement {
    private final String name;
    private final Expression location;

    public MoveHologramStatement(String name, Expression location) {
        this.name = name;
        this.location = location;
    }

    @Override
    public void execute(ExecutionContext context) {
        HologramRuntime.move(name, context.evaluate(location));
    }
}
