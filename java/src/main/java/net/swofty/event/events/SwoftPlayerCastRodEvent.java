package net.swofty.event.events;

import java.util.Map;

import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.fishing.event.PlayerCastRodEvent;
import net.swofty.nativebridge.representation.Event;

/**
 * on PlayerCastRod wrapper (phase 8): player, cancelled. Fires before
 * the bobber spawns; cancelling suppresses the cast.
 */
public class SwoftPlayerCastRodEvent extends AbstractSwoftEvent<PlayerCastRodEvent> {
    public SwoftPlayerCastRodEvent(PlayerCastRodEvent minestomEvent, Event swoftEvent) {
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
