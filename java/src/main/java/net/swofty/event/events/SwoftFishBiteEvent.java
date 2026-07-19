package net.swofty.event.events;

import java.util.Map;

import net.minestom.server.command.CommandSender;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.fishing.event.FishBiteEvent;
import net.swofty.nativebridge.representation.Event;

/**
 * on FishBite wrapper (phase 8): player, hook_location. Fires when the
 * bobber dips and the catch window opens.
 */
public class SwoftFishBiteEvent extends AbstractSwoftEvent<FishBiteEvent> {
    public SwoftFishBiteEvent(FishBiteEvent minestomEvent, Event swoftEvent) {
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

    public Pos getHookLocation() {
        return minestomEvent.getHookLocation();
    }
}
