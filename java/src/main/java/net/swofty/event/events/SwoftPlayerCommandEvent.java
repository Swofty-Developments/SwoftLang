package net.swofty.event.events;

import java.util.Map;

import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.minestom.server.event.player.PlayerCommandEvent;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.nativebridge.representation.Event;

/**
 * Curated wrapper over Minestom's {@link PlayerCommandEvent} (design
 * phase-10 §4). Minestom fires this on the command path BEFORE the command
 * is dispatched, so cancelling it vetoes execution - scripts can block or
 * rewrite commands (admin freeze, command logging). The command string
 * carries no leading slash, matching Minestom.
 *
 * <p>Rows: {@code player} (read-only), {@code command} (read-write - a
 * handler may rewrite the command that will run), {@code cancelled}
 * (read-write veto).
 */
public class SwoftPlayerCommandEvent extends AbstractSwoftEvent<PlayerCommandEvent> {

    public SwoftPlayerCommandEvent(PlayerCommandEvent minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
    }

    @Override
    public CommandSender getSender() {
        return minestomEvent.getPlayer();
    }

    @Override
    protected void addCustomVariables(Map<String, Object> variables) {
        variables.put("player", getPlayer());
        variables.put("command", getCommand());
    }

    public Player getPlayer() {
        return minestomEvent.getPlayer();
    }

    public String getCommand() {
        return minestomEvent.getCommand();
    }

    public void setCommand(String command) {
        minestomEvent.setCommand(command);
    }
}
