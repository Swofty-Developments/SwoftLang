package net.swofty.nativebridge.execution.commands.worlds;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.worlds.WorldsRuntime;

/**
 * create world "arena" [readonly] with &lt;loader&gt; (design 6B).
 */
public class CreateWorldStatement extends AbstractAstNode implements Statement {
    private final Expression name;
    private final Expression loader;
    private final boolean readonly;

    public CreateWorldStatement(Expression name, Expression loader, boolean readonly) {
        this.name = name;
        this.loader = loader;
        this.readonly = readonly;
    }

    @Override
    public void execute(ExecutionContext context) {
        WorldsRuntime.create(
                WorldStatements.name(context, name, "create world"),
                WorldStatements.loader(context, loader, "create world"),
                readonly);
    }
}
