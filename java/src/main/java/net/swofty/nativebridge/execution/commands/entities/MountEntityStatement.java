package net.swofty.nativebridge.execution.commands.entities;

import net.minestom.server.entity.Entity;
import net.swofty.async.TickDispatch;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * mount &lt;entity&gt; on &lt;entity&gt; (phase 7): passenger mounting between any
 * two entity values — plain entities, mobs, players, and displays (a
 * display value unwraps to its backing entity, so the display mount
 * statement and this one compose on the same mechanism).
 */
public class MountEntityStatement extends AbstractAstNode implements Statement {
    private final Expression rider;
    private final Expression vehicle;

    public MountEntityStatement(Expression rider, Expression vehicle) {
        this.rider = rider;
        this.vehicle = vehicle;
    }

    @Override
    public void execute(ExecutionContext context) {
        Entity riderEntity = EntityValues.asEntity(context.evaluate(rider), "mount");
        Entity vehicleEntity = EntityValues.asEntity(context.evaluate(vehicle),
                "mount ... on");
        TickDispatch.call(() -> {
            // self-mounts AND indirect cycles: an unguarded cycle is a
            // StackOverflowError on the tick thread (see EntityValues)
            EntityValues.checkMountCycle(riderEntity, vehicleEntity, "mount");
            vehicleEntity.addPassenger(riderEntity);
            return null;
        });
    }
}
