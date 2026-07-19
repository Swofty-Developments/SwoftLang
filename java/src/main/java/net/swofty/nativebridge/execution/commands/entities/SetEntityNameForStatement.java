package net.swofty.nativebridge.execution.commands.entities;

import net.minestom.server.entity.Entity;
import net.minestom.server.entity.Player;
import net.swofty.ScriptError;
import net.swofty.entities.EntityNametagRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * {@code set name of <entity> to <String> for <player>} (W-viewers, feature 3):
 * set the entity's overhead name as seen by ONE viewer, leaving every other
 * viewer's view (and the entity's real custom name) untouched. Backed by a
 * per-viewer {@link EntityNametagRuntime} metadata packet.
 */
public class SetEntityNameForStatement extends AbstractAstNode implements Statement {
    private final Expression entity;
    private final Expression value;
    private final Expression viewer;

    public SetEntityNameForStatement(Expression entity, Expression value, Expression viewer) {
        this.entity = entity;
        this.value = value;
        this.viewer = viewer;
    }

    public Expression getEntity() {
        return entity;
    }

    public Expression getValue() {
        return value;
    }

    public Expression getViewer() {
        return viewer;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object entityValue = context.evaluate(entity);
        if (!(entityValue instanceof Entity target)) {
            throw new ScriptError("set name of ... expects an entity, got: "
                    + Values.displayString(entityValue));
        }
        String name = (String) Coercions.toStringValue(context.evaluate(value));
        Player viewerPlayer = context.requirePlayer(context.evaluate(viewer),
                "set name of ... for");
        EntityNametagRuntime.set(target, name, viewerPlayer);
    }
}
