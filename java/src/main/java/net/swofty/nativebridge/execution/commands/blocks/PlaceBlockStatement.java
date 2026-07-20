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
 * {@code place <Block|"id"> at <location>} (W-tasks/blocks): imperative block
 * placement into the instance. The block may be a {@link net.swofty.blocks.BlockValue}
 * (carrying state + NBT, e.g. from {@code block(...)}) or a plain block-id
 * String. Replacing the block at a position drops every task bound there, so a
 * {@code block_at(loc).tasks.*} task auto-cancels when the block is replaced.
 */
public class PlaceBlockStatement extends AbstractAstNode implements Statement {
    private final Expression block;
    private final Expression location;

    public PlaceBlockStatement(Expression block, Expression location) {
        this.block = block;
        this.location = location;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object where = context.evaluate(location);
        if (!(where instanceof Pos pos)) {
            throw new ScriptError("place ... at expects a location, got: "
                    + Values.displayString(where));
        }
        Block resolved = SetBlockStatement.resolveBlock(context.evaluate(block));
        Instance instance = SetBlockStatement.resolveInstance(context, null, "place block");
        TickDispatch.call(() -> {
            instance.setBlock(pos.blockX(), pos.blockY(), pos.blockZ(), resolved);
            return null;
        });
        // replacing the block at this position invalidates any tasks bound there
        TaskRegistry.cancelBlock(instance, pos);
    }
}
