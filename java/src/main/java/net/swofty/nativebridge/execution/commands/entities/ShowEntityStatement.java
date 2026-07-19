package net.swofty.nativebridge.execution.commands.entities;

import net.swofty.entities.ViewerControl;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * {@code show <entity> to <player|list&lt;Player&gt;|all>} (W-viewers): add the
 * target(s) as viewer(s) of the entity via Minestom's addViewer. Distinct from
 * the UI {@code show scoreboard/tablist/...} verbs — those keep their own
 * statement kinds; this fires only when the object of {@code show} is an entity
 * expression.
 */
public class ShowEntityStatement extends AbstractAstNode implements Statement {
    private final Expression entity;
    private final Expression target;

    public ShowEntityStatement(Expression entity, Expression target) {
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
        ViewerControl.show(context.evaluate(entity), context.evaluate(target));
    }
}
