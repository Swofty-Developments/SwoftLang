package net.swofty.nativebridge.execution.commands.holograms;

import net.swofty.holograms.HologramRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/** {@code remove hologram "name"} (first-class GROUP D). */
public class RemoveHologramStatement extends AbstractAstNode implements Statement {
    private final String name;

    public RemoveHologramStatement(String name) {
        this.name = name;
    }

    @Override
    public void execute(ExecutionContext context) {
        HologramRuntime.remove(name);
    }
}
