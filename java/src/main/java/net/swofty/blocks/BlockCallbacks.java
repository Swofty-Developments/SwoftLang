package net.swofty.blocks;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.coordinate.Point;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.coordinate.Vec;
import net.minestom.server.instance.block.BlockFace;
import net.swofty.ASTExecutor;
import net.swofty.async.HaltSignal;
import net.swofty.model.BlockCallbackModel;
import net.swofty.runtime.ReturnSignal;
import net.swofty.runtime.SystemSender;

/**
 * Shared invocation machinery for {@code block_handler} / {@code placement_rule}
 * callbacks (W-blocks): bind the callback's declared positional params to the
 * Minestom event/state fields and run the body through an {@link ASTExecutor},
 * optionally capturing a returned value (placement rules and {@code on_interact}
 * return; the void callbacks do not).
 *
 * <p>Errors are isolated so a misbehaving script callback never takes down the
 * firing block event or placement.
 */
public final class BlockCallbacks {

    private BlockCallbacks() {
    }

    /** A block position as a script location. */
    public static Pos location(Point point) {
        return new Pos(point);
    }

    /** A cursor/offset point as a script vector. */
    public static Vec vector(Point point) {
        return new Vec(point.x(), point.y(), point.z());
    }

    /** The lowercased block-face name (north/south/east/west/top/bottom). */
    public static String faceName(BlockFace face) {
        return face == null ? "" : face.name().toLowerCase();
    }

    /** Bind params positionally to args, plus any extra fixed bindings. */
    public static Map<String, Object> bind(BlockCallbackModel callback, Object... args) {
        Map<String, Object> vars = new HashMap<>();
        List<String> params = callback.params();
        for (int i = 0; i < params.size() && i < args.length; i++) {
            vars.put(params.get(i), args[i]);
        }
        return vars;
    }

    /** Run a void callback body, swallowing script errors. */
    public static void run(CommandSender sender, BlockCallbackModel callback,
            Map<String, Object> vars, String label) {
        runReturning(sender, callback, vars, label);
    }

    /**
     * Run a callback body and return the value from a top-level {@code return}
     * (null when the body falls off the end or halts). Script errors are
     * caught and reported, yielding null.
     */
    public static Object runReturning(CommandSender sender, BlockCallbackModel callback,
            Map<String, Object> vars, String label) {
        if (callback == null || callback.body() == null || callback.body().isEmpty()) {
            return null;
        }
        try {
            ASTExecutor executor = new ASTExecutor(
                    sender != null ? sender : consoleSender(), vars);
            try {
                executor.context().runBlock(callback.body());
                return null;
            } catch (ReturnSignal signal) {
                return signal.getValue();
            } catch (HaltSignal halt) {
                return null;
            }
        } catch (Exception e) {
            System.err.println("Error in " + label + " callback: " + e.getMessage());
            return null;
        }
    }

    static CommandSender consoleSender() {
        try {
            return MinecraftServer.getCommandManager().getConsoleSender();
        } catch (Throwable t) {
            return SystemSender.INSTANCE;
        }
    }
}
