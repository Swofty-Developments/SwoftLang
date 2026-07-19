package net.swofty.nativebridge.execution.commands.entities;

import net.minestom.server.entity.Entity;
import net.swofty.async.TickDispatch;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * dismount &lt;entity&gt; (phase 7): detach the entity from its current
 * vehicle; a no-op when it is not riding anything.
 */
public class DismountEntityStatement extends AbstractAstNode implements Statement {
    private final Expression target;

    public DismountEntityStatement(Expression target) {
        this.target = target;
    }

    @Override
    public void execute(ExecutionContext context) {
        Entity entity = EntityValues.asEntity(context.evaluate(target), "dismount");
        TickDispatch.call(() -> {
            Entity vehicle = entity.getVehicle();
            if (vehicle != null) {
                vehicle.removePassenger(entity);
            }
            return null;
        });
    }
}
