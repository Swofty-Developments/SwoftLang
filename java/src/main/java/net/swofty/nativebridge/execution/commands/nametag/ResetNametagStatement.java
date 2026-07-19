package net.swofty.nativebridge.execution.commands.nametag;

import net.minestom.server.entity.Player;
import net.swofty.nametags.NametagRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * reset nametag of &lt;player&gt; [for &lt;viewer&gt;] (design 5C): drops the
 * per-viewer override, or the whole default view when no viewer is given.
 */
public class ResetNametagStatement extends AbstractAstNode implements Statement {
    private final Expression target;
    private final Expression viewer;

    public ResetNametagStatement(Expression target, Expression viewer) {
        this.target = target;
        this.viewer = viewer;
    }

    @Override
    public void execute(ExecutionContext context) {
        Player targetPlayer = context.requirePlayer(context.evaluate(target), "reset nametag");
        SetNametagStatement.forEachViewer(context, viewer, viewerPlayer ->
                NametagRuntime.reset(targetPlayer, viewerPlayer));
    }
}
