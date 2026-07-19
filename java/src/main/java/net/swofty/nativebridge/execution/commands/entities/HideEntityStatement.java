package net.swofty.nativebridge.execution.commands.entities;

import net.swofty.entities.ViewerControl;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * {@code hide <entity> from <player|list&lt;Player&gt;|all>} (W-viewers): remove
 * the target(s) from the entity's viewer set via Minestom's removeViewer, and
 * drop any per-viewer overhead name they held on it.
 */
public class HideEntityStatement extends AbstractAstNode implements Statement {
    private final Expression entity;
    private final Expression target;

    public HideEntityStatement(Expression entity, Expression target) {
        this.entity = entity;
        this.target = target;
    }

    public Expression getEntity() {
        return entity;
    }

    public Expression getTarget() {
        return target;
    }

    @Override
    public void execute(ExecutionContext context) {
        ViewerControl.hide(context.evaluate(entity), context.evaluate(target));
    }
}
