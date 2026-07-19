package net.swofty.runtime;

import java.util.ArrayList;
import java.util.List;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.instance.Instance;
import net.swofty.ScriptError;
import net.swofty.props.NoneValue;

/**
 * Shared player-target resolution for phase-6 statements: a Player, the
 * string "all" (or none = sender), a collection of players, optionally
 * narrowed to a radius around a location.
 */
public final class PlayerTargets {
    private PlayerTargets() {
    }

    /**
     * Resolve a target value into concrete players. none resolves to the
     * sender when it is a player, otherwise an error naming the statement.
     */
    public static List<Player> resolve(ExecutionContext context, Object resolved, String what) {
        List<Player> players = new ArrayList<>();
        if (NoneValue.isNone(resolved) || "sender".equals(resolved)) {
            if (context.getSender() instanceof Player player) {
                players.add(player);
                return players;
            }
            throw new ScriptError(what + " needs a player target (the sender is not a player)");
        }
        if ("all".equals(resolved)) {
            players.addAll(MinecraftServer.getConnectionManager().getOnlinePlayers());
            return players;
        }
        if (resolved instanceof Player player) {
            players.add(player);
            return players;
        }
        if (resolved instanceof Iterable<?> iterable) {
            for (Object element : iterable) {
                if (element instanceof Player player) {
                    players.add(player);
                }
            }
            return players;
        }
        throw new ScriptError(what + " expects a player (or 'all'), got: "
                + Values.displayString(resolved));
    }

    /** Every online player within radius of a location in an instance. */
    public static List<Player> withinRadius(Instance instance, Pos center, double radius) {
        List<Player> players = new ArrayList<>();
        double radiusSq = radius * radius;
        for (Player player : MinecraftServer.getConnectionManager().getOnlinePlayers()) {
            if (instance != null && player.getInstance() != instance) {
                continue;
            }
            if (player.getPosition().distanceSquared(center) <= radiusSq) {
                players.add(player);
            }
        }
        return players;
    }
}
