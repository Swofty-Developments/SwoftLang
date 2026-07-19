package net.swofty.nativebridge.execution.commands.holograms;

import net.swofty.holograms.HologramRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;

/** {@code set hologram "name" line <n> to <expr>} (0-based; GROUP D). */
public class SetHologramLineStatement extends AbstractAstNode implements Statement {
    private final String name;
    private final Expression index;
    private final Expression value;

    public SetHologramLineStatement(String name, Expression index, Expression value) {
        this.name = name;
        this.index = index;
        this.value = value;
    }

    @Override
    public void execute(ExecutionContext context) {
        int line = Coercions.requireNumber(context.evaluate(index), "hologram line index").intValue();
        HologramRuntime.setLine(name, line, context.evaluate(value));
    }
}
