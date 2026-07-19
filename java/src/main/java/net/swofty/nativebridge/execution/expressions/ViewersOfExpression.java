package net.swofty.nativebridge.execution.expressions;

import net.swofty.entities.ViewerControl;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ExecutionContext;

/**
 * {@code viewers of <entity>} (W-viewers): the entity's current viewers as an
 * ordered {@code list&lt;Player&gt;}. Minestom's {@code getViewers()} is an
 * unordered set, so {@link ViewerControl#viewersOf} sorts by username for a
 * stable, script-visible order.
 */
public class ViewersOfExpression extends AbstractAstNode implements Expression {
    private final Expression entity;

    public ViewersOfExpression(Expression entity) {
        this.entity = entity;
    }

    public Expression getEntity() {
        return entity;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        return ViewerControl.viewersOf(context.evaluate(entity));
    }
}
