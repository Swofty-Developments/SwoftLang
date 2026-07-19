package net.swofty.event.events;

import java.util.Map;

import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.fishing.event.PlayerReelInEvent;
import net.swofty.nativebridge.representation.Event;

/**
 * on PlayerReelIn wrapper (phase 8): player. Fires on every reel-in,
 * catch or not.
 */
public class SwoftPlayerReelInEvent extends AbstractSwoftEvent<PlayerReelInEvent> {
    public SwoftPlayerReelInEvent(PlayerReelInEvent minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
    }

    @Override
    public CommandSender getSender() {
        return minestomEvent.getPlayer();
    }

    @Override
    protected void addCustomVariables(Map<String, Object> variables) {
        variables.put("player", minestomEvent.getPlayer());
    }

    public Player getPlayer() {
        return minestomEvent.getPlayer();
    }
}
