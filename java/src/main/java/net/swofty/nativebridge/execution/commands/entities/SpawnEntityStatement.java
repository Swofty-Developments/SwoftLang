package net.swofty.nativebridge.execution.commands.entities;

import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.EntityType;
import net.minestom.server.instance.Instance;
import net.swofty.ScriptError;
import net.swofty.async.TickDispatch;
import net.swofty.mobs.SwoftMob;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * spawn entity "TYPE" at &lt;location&gt; [as &lt;var&gt;] (phase 7). The type is
 * any Minestom EntityType key ("ARMOR_STAND", "minecraft:zombie"); the
 * instance is the spawner's world when available, else the default
 * overworld ("world").
 */
public class SpawnEntityStatement extends AbstractAstNode implements Statement {
    private final Expression type;
    private final Expression location;
    private final String bindVar;

    public SpawnEntityStatement(Expression type, Expression location, String bindVar) {
        this.type = type;
        this.location = location;
        this.bindVar = bindVar;
    }

    @Override
    public void execute(ExecutionContext context) {
        String typeName = (String) Coercions.toStringValue(context.evaluate(type));
        Object where = context.evaluate(location);
        if (!(where instanceof Pos pos)) {
            throw new ScriptError("spawn entity expects a location, got: "
                    + Values.displayString(where));
        }
        EntityType entityType = SwoftMob.resolveType(typeName);
        Instance instance = EntityValues.spawnInstance(context, "spawn entity");

        Entity entity = new Entity(entityType);
        TickDispatch.call(() -> {
            entity.setInstance(instance, pos);
            // reload/shutdown sweep parity with displays and mobs
            net.swofty.entities.ScriptEntityRegistry.track(entity);
            return null;
        });
        if (bindVar != null) {
            context.getVariables().put(bindVar, entity);
        }
    }
}
