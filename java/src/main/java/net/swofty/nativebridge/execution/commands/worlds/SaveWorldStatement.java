package net.swofty.nativebridge.execution.commands.worlds;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.worlds.WorldsRuntime;

/**
 * save world "arena" (design 6B).
 */
public class SaveWorldStatement extends AbstractAstNode implements Statement {
    private final Expression name;

    public SaveWorldStatement(Expression name) {
        this.name = name;
    }

    @Override
    public void execute(ExecutionContext context) {
        WorldsRuntime.save(WorldStatements.name(context, name, "save world"));
    }
}
