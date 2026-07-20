package net.swofty.nativebridge.execution.commands.blocks;

import net.minestom.server.coordinate.Pos;
import net.minestom.server.instance.Instance;
import net.minestom.server.instance.block.Block;
import net.swofty.ScriptError;
import net.swofty.async.TickDispatch;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;
import net.swofty.tasks.TaskRegistry;

/**
 * {@code remove block at <location>} (W-tasks/blocks): set the position to air
 * and cancel every task bound to that position. The block-position task bucket
 * is dropped so a {@code block_at(loc).tasks.*} task stops the moment its block
 * is removed.
 */
public class RemoveBlockStatement extends AbstractAstNode implements Statement {
    private final Expression location;

    public RemoveBlockStatement(Expression location) {
        this.location = location;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object where = context.evaluate(location);
        if (!(where instanceof Pos pos)) {
            throw new ScriptError("remove block at expects a location, got: "
                    + Values.displayString(where));
        }
        Instance instance = SetBlockStatement.resolveInstance(context, null, "remove block");
        TickDispatch.call(() -> {
            instance.setBlock(pos.blockX(), pos.blockY(), pos.blockZ(), Block.AIR);
            return null;
        });
        TaskRegistry.cancelBlock(instance, pos);
    }
}
