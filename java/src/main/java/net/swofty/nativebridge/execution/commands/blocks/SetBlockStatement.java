package net.swofty.nativebridge.execution.commands.blocks;

import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.instance.Instance;
import net.minestom.server.instance.block.Block;
import net.swofty.InstanceRegistry;
import net.swofty.ScriptError;
import net.swofty.async.TickDispatch;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * set block at &lt;location&gt; to "STONE" [in &lt;world&gt;] (design 6D). The
 * instance defaults to the sender player's world, else "world".
 */
public class SetBlockStatement extends AbstractAstNode implements Statement {
    private final Expression location;
    private final Expression block;
    private final Expression world;

    public SetBlockStatement(Expression location, Expression block, Expression world) {
        this.location = location;
        this.block = block;
        this.world = world;
    }

    public static Block resolveBlock(String name) {
        String key = name.contains(":") ? name.toLowerCase() : "minecraft:" + name.toLowerCase();
        Block resolved = Block.fromKey(key);
        if (resolved == null) {
            throw new ScriptError("unknown block '" + name + "'");
        }
        return resolved;
    }

    /** Instance from an explicit expr, the sender's world, or "world". */
    public static Instance resolveInstance(ExecutionContext context, Expression world,
            String what) {
        if (world != null) {
            return (Instance) Coercions.toInstance(context.evaluate(world));
        }
        if (context.getSender() instanceof Player player && player.getInstance() != null) {
            return player.getInstance();
        }
        Instance fallback = InstanceRegistry.get("world");
        if (fallback == null) {
            throw new ScriptError(what + ": no world available "
                    + "(sender is not a player and no default world is registered)");
        }
        return fallback;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object where = context.evaluate(location);
        if (!(where instanceof Pos pos)) {
            throw new ScriptError("set block expects a location, got: "
                    + Values.displayString(where));
        }
        Block resolved = resolveBlock(
                (String) Coercions.toStringValue(context.evaluate(block)));
        Instance instance = resolveInstance(context, world, "set block");
        TickDispatch.call(() -> {
            instance.setBlock(pos.blockX(), pos.blockY(), pos.blockZ(), resolved);
            return null;
        });
    }
}
