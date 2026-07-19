package net.swofty.nativebridge.execution.commands.worlds;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.worlds.WorldsRuntime;

/**
 * clone world "a" to "b" with &lt;loader&gt; (design 6B): duplicates stored
 * world data without loading either world.
 */
public class CloneWorldStatement extends AbstractAstNode implements Statement {
    private final Expression from;
    private final Expression to;
    private final Expression loader;

    public CloneWorldStatement(Expression from, Expression to, Expression loader) {
        this.from = from;
        this.to = to;
        this.loader = loader;
    }

    @Override
    public void execute(ExecutionContext context) {
        String source = WorldStatements.name(context, from, "clone world");
        String target = WorldStatements.name(context, to, "clone world");
        WorldsRuntime.validateName(target);
        WorldStatements.loader(context, loader, "clone world").clone(source, target);
    }
}
