package net.swofty.nativebridge.execution.commands.npcs;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.npcs.NpcRuntime;
import net.swofty.runtime.ExecutionContext;

/** {@code set npc "name" location <location>} — teleport the NPC (GROUP C). */
public class SetNpcLocationStatement extends AbstractAstNode implements Statement {
    private final String name;
    private final Expression location;

    public SetNpcLocationStatement(String name, Expression location) {
        this.name = name;
        this.location = location;
    }

    @Override
    public void execute(ExecutionContext context) {
        NpcRuntime.setLocation(name, context.evaluate(location));
    }
}
