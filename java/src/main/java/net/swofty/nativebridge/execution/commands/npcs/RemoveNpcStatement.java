package net.swofty.nativebridge.execution.commands.npcs;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.npcs.NpcRuntime;
import net.swofty.runtime.ExecutionContext;

/** {@code remove npc "name"} — despawn and drop all state (GROUP C). */
public class RemoveNpcStatement extends AbstractAstNode implements Statement {
    private final String name;

    public RemoveNpcStatement(String name) {
        this.name = name;
    }

    @Override
    public void execute(ExecutionContext context) {
        NpcRuntime.remove(name);
    }
}
