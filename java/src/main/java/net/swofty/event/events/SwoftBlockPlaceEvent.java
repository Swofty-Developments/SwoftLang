package net.swofty.event.events;

import net.minestom.server.command.CommandSender;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.event.player.PlayerBlockPlaceEvent;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.nativebridge.representation.Event;

/**
 * event BlockPlace { player, block, location, cancelled } wrapper over
 * PlayerBlockPlaceEvent (design 6D).
 */
public class SwoftBlockPlaceEvent extends AbstractSwoftEvent<PlayerBlockPlaceEvent> {
    public SwoftBlockPlaceEvent(PlayerBlockPlaceEvent minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
    }

    public Player getPlayer() {
        return minestomEvent.getPlayer();
    }

    /** Block key, e.g. "minecraft:stone". */
    public String getBlock() {
        return minestomEvent.getBlock().name();
    }

    public Pos getLocation() {
        var position = minestomEvent.getBlockPosition();
        return new Pos(position.x(), position.y(), position.z());
    }

    /** Clicked block face, lowercase (e.g. "top"). */
    public String getBlockFace() {
        return minestomEvent.getBlockFace().name().toLowerCase(java.util.Locale.ROOT);
    }

    /** Interaction hand: "main" or "off". */
    public String getHand() {
        return minestomEvent.getHand().name().toLowerCase(java.util.Locale.ROOT);
    }

    /** Where on the block face the player clicked. */
    public Pos getCursorPosition() {
        var cursor = minestomEvent.getCursorPosition();
        return new Pos(cursor.x(), cursor.y(), cursor.z());
    }

    @Override
    public CommandSender getSender() {
        return minestomEvent.getPlayer();
    }
}
