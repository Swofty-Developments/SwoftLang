package net.swofty.nativebridge.execution.commands;

import java.util.function.Supplier;

import net.minestom.server.command.CommandSender;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.swofty.async.TickDispatch;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

public class TeleportCommand extends AbstractAstNode implements Statement {
    private final Expression entity;
    private final Expression target;

    public TeleportCommand(Expression entity, Expression target) {
        this.entity = entity;
        this.target = target;
    }

    public Expression getEntity() {
        return entity;
    }

    public Expression getTarget() {
        return target;
    }

    /**
     * Execute a teleport command
     */
    @Override
    public void execute(ExecutionContext context) {
        Object entityValue = context.evaluate(entity);
        Object targetValue = context.evaluate(target);
        CommandSender sender = context.getSender();

        if (!(entityValue instanceof Player)) {
            sender.sendMessage("Error: Cannot teleport non-player entity");
            return;
        }

        Player player = (Player) entityValue;

        if (targetValue instanceof Player) {
            // Teleport to player; position read + teleport hop to the tick thread
            Player targetPlayer = (Player) targetValue;
            teleportOnTick(player, () -> targetPlayer.getPosition());

            if (player != sender && sender instanceof Player) {
                sender.sendMessage("Teleported " + player.getUsername() + " to " + targetPlayer.getUsername());
            }
        } else if (targetValue instanceof Pos) {
            // Teleport to location
            Pos position = (Pos) targetValue;
            teleportOnTick(player, () -> position);

            if (player != sender && sender instanceof Player) {
                sender.sendMessage("Teleported " + player.getUsername() + " to " +
                        String.format("%.2f, %.2f, %.2f", position.x(), position.y(), position.z()));
            }
        } else {
            sender.sendMessage("Error: Cannot teleport to " + targetValue + " - not a player or location");
        }
    }

    /**
     * Teleport is a TICK mutation: read the target position and move the
     * entity inside one TickDispatch.call, with the same offline staleness
     * guard TICK property setters get.
     */
    private static void teleportOnTick(Player player, Supplier<Pos> target) {
        TickDispatch.call(() -> {
            if (!player.isOnline()) {
                System.err.println("Debug: skipping teleport: player "
                        + player.getUsername() + " is offline");
                return null;
            }
            player.teleport(target.get());
            return null;
        });
    }
}
