package net.swofty.nativebridge.execution.commands.mobs;

import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.instance.Instance;
import net.swofty.InstanceRegistry;
import net.swofty.ScriptError;
import net.swofty.mobs.MobRegistry;
import net.swofty.mobs.SwoftMob;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * spawn mob "id" at &lt;location&gt; [as &lt;var&gt;] (design 5B). The instance is
 * the sender player's world when available, else the default "world".
 */
public class SpawnMobStatement extends AbstractAstNode implements Statement {
    private final Expression mobId;
    private final Expression location;
    private final String bindVar;

    public SpawnMobStatement(Expression mobId, Expression location, String bindVar) {
        this.mobId = mobId;
        this.location = location;
        this.bindVar = bindVar;
    }

    @Override
    public void execute(ExecutionContext context) {
        String id = (String) Coercions.toStringValue(context.evaluate(mobId));
        Object where = context.evaluate(location);
        if (!(where instanceof Pos pos)) {
            throw new ScriptError("spawn mob expects a location, got: "
                    + Values.displayString(where));
        }
        Instance instance = context.getSender() instanceof Player player
                && player.getInstance() != null
                ? player.getInstance()
                : InstanceRegistry.get("world");
        SwoftMob mob = MobRegistry.spawn(id, pos, instance);
        if (bindVar != null) {
            context.getVariables().put(bindVar, mob);
        }
    }
}
