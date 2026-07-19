package net.swofty.nativebridge.execution.commands.worlds;

import java.nio.file.Path;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;
import net.swofty.worlds.WorldsRuntime;

/**
 * import anvil world "path" as "name" with &lt;loader&gt; (design 6B):
 * vanilla anvil directory into the loader's storage.
 */
public class ImportWorldStatement extends AbstractAstNode implements Statement {
    private final Expression anvilPath;
    private final Expression name;
    private final Expression loader;

    public ImportWorldStatement(Expression anvilPath, Expression name, Expression loader) {
        this.anvilPath = anvilPath;
        this.name = name;
        this.loader = loader;
    }

    @Override
    public void execute(ExecutionContext context) {
        String path = (String) Coercions.toStringValue(context.evaluate(anvilPath));
        String worldName = WorldStatements.name(context, name, "import world");
        WorldsRuntime.validateName(worldName);
        WorldStatements.loader(context, loader, "import world")
                .importAnvil(Path.of(path), worldName);
    }
}
