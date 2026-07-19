package net.swofty.nativebridge.execution.commands.blocks;

import net.minestom.server.coordinate.Pos;
import net.minestom.server.instance.Instance;
import net.minestom.server.instance.block.Block;
import net.swofty.ScriptError;
import net.swofty.async.TickDispatch;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * fill blocks from &lt;loc&gt; to &lt;loc&gt; with "X" (design 6D). Bounded: the
 * volume cap keeps a stray script from freezing the tick thread (the
 * checker additionally warns on large literals).
 */
public class FillBlocksStatement extends AbstractAstNode implements Statement {
    /** ~ a 64x32x64 box. */
    public static final int MAX_VOLUME = 131_072;

    private final Expression from;
    private final Expression to;
    private final Expression block;
    private final Expression world;

    public FillBlocksStatement(Expression from, Expression to, Expression block,
            Expression world) {
        this.from = from;
        this.to = to;
        this.block = block;
        this.world = world;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object fromValue = context.evaluate(from);
        Object toValue = context.evaluate(to);
        if (!(fromValue instanceof Pos a) || !(toValue instanceof Pos b)) {
            throw new ScriptError("fill blocks expects two locations, got: "
                    + Values.displayString(fromValue) + " and " + Values.displayString(toValue));
        }
        Block resolved = SetBlockStatement.resolveBlock(
                (String) Coercions.toStringValue(context.evaluate(block)));
        Instance instance = SetBlockStatement.resolveInstance(context, world, "fill blocks");

        int minX = Math.min(a.blockX(), b.blockX());
        int maxX = Math.max(a.blockX(), b.blockX());
        int minY = Math.min(a.blockY(), b.blockY());
        int maxY = Math.max(a.blockY(), b.blockY());
        int minZ = Math.min(a.blockZ(), b.blockZ());
        int maxZ = Math.max(a.blockZ(), b.blockZ());

        long volume = (long) (maxX - minX + 1) * (maxY - minY + 1) * (maxZ - minZ + 1);
        if (volume > MAX_VOLUME) {
            throw new ScriptError("fill blocks volume " + volume + " exceeds the cap of "
                    + MAX_VOLUME + " blocks");
        }

        TickDispatch.call(() -> {
            for (int x = minX; x <= maxX; x++) {
                for (int y = minY; y <= maxY; y++) {
                    for (int z = minZ; z <= maxZ; z++) {
                        instance.setBlock(x, y, z, resolved);
                    }
                }
            }
            return null;
        });
    }
}
