package net.swofty.nativebridge.execution.commands.mobs;

import net.minestom.server.entity.EntityCreature;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * {@code stop pathing <mob>} (design v1.9.0 §5): resets the creature's
 * {@link net.minestom.server.entity.pathfinding.Navigator}, cancelling any
 * active path.
 */
public class StopPathingStatement extends AbstractAstNode implements Statement {
    private final Expression mob;

    public StopPathingStatement(Expression mob) {
        this.mob = mob;
    }

    @Override
    public void execute(ExecutionContext context) {
        EntityCreature creature = PathStatement.requireCreature(context.evaluate(mob));
        creature.getNavigator().reset();
    }
}
