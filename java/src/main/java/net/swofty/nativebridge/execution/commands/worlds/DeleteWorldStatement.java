package net.swofty.nativebridge.execution.commands.worlds;

import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.worlds.WorldsRuntime;

/**
 * delete world "arena" with &lt;loader&gt; (design 6B): the world must be
 * unloaded first.
 */
public class DeleteWorldStatement extends AbstractAstNode implements Statement {
    private final Expression name;
    private final Expression loader;

    public DeleteWorldStatement(Expression name, Expression loader) {
        this.name = name;
        this.loader = loader;
    }

    @Override
    public void execute(ExecutionContext context) {
        String worldName = WorldStatements.name(context, name, "delete world");
        if (WorldsRuntime.isLoaded(worldName)) {
            throw new ScriptError("world '" + worldName + "' is loaded - unload it first");
        }
        WorldStatements.loader(context, loader, "delete world").delete(worldName);
    }
}
