package net.swofty.nativebridge.execution.commands.npcs;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.npcs.NpcRuntime;
import net.swofty.runtime.ExecutionContext;

/** {@code set npc "name" name <expr>} — overhead name override (GROUP C). */
public class SetNpcNameStatement extends AbstractAstNode implements Statement {
    private final String name;
    private final Expression value;

    public SetNpcNameStatement(String name, Expression value) {
        this.name = name;
        this.value = value;
    }

    @Override
    public void execute(ExecutionContext context) {
        NpcRuntime.setName(name, context.evaluate(value));
    }
}
