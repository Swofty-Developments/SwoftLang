package net.swofty.entities;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;

import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.Player;
import net.swofty.ScriptError;
import net.swofty.async.TickDispatch;
import net.swofty.props.NoneValue;
import net.swofty.runtime.Values;

/**
 * The English viewer-control verbs over any {@link Entity} (W-viewers):
 *
 * <ul>
 *   <li>{@code show <entity> to <player|list&lt;Player&gt;|all>} — add viewer(s)
 *       through Minestom's {@link Entity#addViewer(Player)} (javap-verified
 *       against 26.2: {@code Viewable.addViewer/removeViewer/getViewers}).</li>
 *   <li>{@code hide <entity> from <player|list&lt;Player&gt;|all>} — remove
 *       viewer(s) via {@link Entity#removeViewer(Player)}.</li>
 *   <li>{@code viewers of <entity>} — the entity's current viewers as an
 *       ordered {@code list&lt;Player&gt;} (sorted by username so the script sees
 *       a stable order, since {@code getViewers()} is an unordered set).</li>
 * </ul>
 *
 * <p>Viewer mutation is a world-thread operation (it spawns/destroys the entity
 * for that connection), so both verbs hop onto the tick thread through
 * {@link TickDispatch}, exactly like {@link net.swofty.npcs.NpcRuntime}'s
 * refresh path. Per-viewer overhead names ({@link EntityNametagRuntime}) are
 * re-applied on show and dropped on hide so a name override never outlives the
 * view it was attached to.
 */
public final class ViewerControl {

    private ViewerControl() {
    }

    /** {@code show <entity> to <target>}. */
    public static void show(Object entityValue, Object target) {
        Entity entity = requireEntity(entityValue, "show");
        List<Player> players = targets(target, "show ... to");
        TickDispatch.call(() -> {
            for (Player player : players) {
                if (entity.addViewer(player)) {
                    // a fresh spawn resets client-side metadata, so re-push any
                    // per-viewer overhead name this viewer had on the entity
                    EntityNametagRuntime.reapply(entity, player);
                }
            }
            return null;
        });
    }

    /** {@code hide <entity> from <target>}. */
    public static void hide(Object entityValue, Object target) {
        Entity entity = requireEntity(entityValue, "hide");
        List<Player> players = targets(target, "hide ... from");
        TickDispatch.call(() -> {
            for (Player player : players) {
                entity.removeViewer(player);
                EntityNametagRuntime.clearHidden(entity, player);
            }
            return null;
        });
    }

    /** {@code viewers of <entity>} — ordered {@code list&lt;Player&gt;}. */
    public static List<Player> viewersOf(Object entityValue) {
        Entity entity = requireEntity(entityValue, "viewers of");
        return orderedViewers(entity);
    }

    /** The property-registry getter for {@code entity.viewers} (Entity.class). */
    public static List<Player> orderedViewers(Entity entity) {
        List<Player> viewers = new ArrayList<>(entity.getViewers());
        viewers.sort(Comparator.comparing(Player::getUsername));
        return viewers;
    }

    private static Entity requireEntity(Object value, String what) {
        if (value instanceof Entity entity) {
            return entity;
        }
        throw new ScriptError(what + " expects an entity, got: " + Values.displayString(value));
    }

    /**
     * Resolve a viewer target the same way the UI show/hide verbs do: a single
     * player, a list of players, or {@code all} (a live Player collection, the
     * literal {@code "all"}, or none) meaning every online player.
     */
    private static List<Player> targets(Object value, String what) {
        if ("all".equals(value) || NoneValue.isNone(value)) {
            return new ArrayList<>(MinecraftServer.getConnectionManager().getOnlinePlayers());
        }
        if (value instanceof Player player) {
            return List.of(player);
        }
        if (value instanceof Collection<?> collection) {
            List<Player> players = new ArrayList<>();
            for (Object element : collection) {
                if (element instanceof Player player) {
                    players.add(player);
                } else {
                    throw new ScriptError(what + " target list must hold players, got: "
                            + Values.displayString(element));
                }
            }
            return players;
        }
        throw new ScriptError(what + " expects a player, a list of players, or all, got: "
                + Values.displayString(value));
    }
}
