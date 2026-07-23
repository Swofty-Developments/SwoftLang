package net.swofty.mobs.ai;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.ai.TargetSelector;
import net.swofty.ASTExecutor;
import net.swofty.mobs.SwoftMob;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ReturnSignal;
import net.swofty.runtime.SystemSender;

/**
 * A {@link TargetSelector} backing a custom {@code target { ... return <Entity> }}
 * block (design v1.9.0 §4). {@code findTarget} runs the emitted body on the tick
 * thread with {@code mob} bound and reads the {@code return} value: an
 * {@link Entity} becomes the tick's target, {@code none} / no entity / an empty
 * {@link Optional} means no target this tick. Errors are isolated to "no target".
 */
public final class ScriptedTargetSelector extends TargetSelector {

    private final SwoftMob mob;
    private final ExecuteBlock body;

    public ScriptedTargetSelector(SwoftMob mob, ExecuteBlock body) {
        super(mob);
        this.mob = mob;
        this.body = body;
    }

    @Override
    public Entity findTarget() {
        if (body == null || body.isEmpty()) {
            return null;
        }
        Map<String, Object> vars = new HashMap<>();
        vars.put("mob", mob);
        try {
            new ASTExecutor(sender(), vars).context().runBlock(body);
            return null; // fell off the end with no return => no target
        } catch (ReturnSignal signal) {
            return unwrap(signal.getValue());
        } catch (Exception e) {
            System.err.println("Error in mob '" + mob.getDef().id()
                    + "' target block: " + e.getMessage());
            return null;
        }
    }

    private static Entity unwrap(Object value) {
        if (value instanceof Optional<?> optional) {
            value = optional.orElse(null);
        }
        if (value == null || NoneValue.isNone(value)) {
            return null;
        }
        if (value instanceof Entity entity) {
            return entity;
        }
        return null;
    }

    private static CommandSender sender() {
        try {
            return MinecraftServer.getCommandManager().getConsoleSender();
        } catch (Throwable t) {
            return SystemSender.INSTANCE;
        }
    }
}
