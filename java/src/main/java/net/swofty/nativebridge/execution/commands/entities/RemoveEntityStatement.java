package net.swofty.nativebridge.execution.commands.entities;

import net.minestom.server.entity.Entity;
import net.swofty.async.TickDispatch;
import net.swofty.displays.SwoftDisplay;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * remove entity &lt;entity&gt; (phase 7). Mobs untrack themselves through
 * SwoftMob.remove; displays destroy through their own lifecycle so the
 * display registry stays consistent.
 */
public class RemoveEntityStatement extends AbstractAstNode implements Statement {
    private final Expression target;

    public RemoveEntityStatement(Expression target) {
        this.target = target;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object value = context.evaluate(target);
        if (value instanceof SwoftDisplay display) {
            display.destroy();
            return;
        }
        Entity entity = EntityValues.asEntity(value, "remove entity");
        TickDispatch.call(() -> {
            entity.remove();
            net.swofty.entities.ScriptEntityRegistry.untrack(entity);
            return null;
        });
    }
}
