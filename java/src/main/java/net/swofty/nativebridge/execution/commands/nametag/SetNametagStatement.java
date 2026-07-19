package net.swofty.nativebridge.execution.commands.nametag;

import java.util.Collection;
import java.util.function.Consumer;

import net.minestom.server.entity.Player;
import net.swofty.nametags.NametagRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;

/**
 * set nametag [prefix|suffix|color] of &lt;player&gt; to &lt;value&gt; [for &lt;viewer&gt;]
 * (design 5C). No viewer = the default view seen by all viewers.
 */
public class SetNametagStatement extends AbstractAstNode implements Statement {
    private final NametagRuntime.Part part;
    private final Expression target;
    private final Expression value;
    private final Expression viewer;

    public SetNametagStatement(NametagRuntime.Part part, Expression target,
            Expression value, Expression viewer) {
        this.part = part;
        this.target = target;
        this.value = value;
        this.viewer = viewer;
    }

    @Override
    public void execute(ExecutionContext context) {
        Player targetPlayer = context.requirePlayer(context.evaluate(target), "set nametag");
        String text = (String) Coercions.toStringValue(context.evaluate(value));
        forEachViewer(context, viewer, viewerPlayer ->
                NametagRuntime.set(targetPlayer, part, text, viewerPlayer));
    }

    /**
     * Viewer resolution shared with reset. No viewer / none / "all" is the
     * broadcast form (one null-viewer application to the default view); a
     * single player applies one per-viewer override; a player collection
     * ('all players', '[a, b]') applies the override once per member -
     * mirroring how send/give resolve their list targets.
     */
    static void forEachViewer(ExecutionContext context, Expression viewer,
            Consumer<Player> action) {
        if (viewer == null) {
            action.accept(null);
            return;
        }
        Object resolved = context.evaluate(viewer);
        if (NoneValue.isNone(resolved) || "all".equals(resolved)) {
            action.accept(null);
            return;
        }
        if (resolved instanceof Collection<?> collection) {
            for (Object element : collection) {
                action.accept(context.requirePlayer(element, "nametag viewer"));
            }
            return;
        }
        action.accept(context.requirePlayer(resolved, "nametag viewer"));
    }
}
