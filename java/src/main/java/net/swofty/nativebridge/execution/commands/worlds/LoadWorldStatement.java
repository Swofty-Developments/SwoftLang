package net.swofty.nativebridge.execution.commands.worlds;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.worlds.WorldsRuntime;

/**
 * load world "arena" with &lt;loader&gt; (design 6B): the stored world must
 * exist; loading an already-loaded world is a no-op.
 */
public class LoadWorldStatement extends AbstractAstNode implements Statement {
    private final Expression name;
    private final Expression loader;

    public LoadWorldStatement(Expression name, Expression loader) {
        this.name = name;
        this.loader = loader;
    }

    @Override
    public void execute(ExecutionContext context) {
        WorldsRuntime.load(
                WorldStatements.name(context, name, "load world"),
                WorldStatements.loader(context, loader, "load world"));
    }
}
