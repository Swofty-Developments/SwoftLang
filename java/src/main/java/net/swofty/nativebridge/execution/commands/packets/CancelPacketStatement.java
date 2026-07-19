package net.swofty.nativebridge.execution.commands.packets;

import net.minestom.server.event.player.PlayerPacketEvent;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.packets.PacketListeners;
import net.swofty.runtime.ExecutionContext;

/**
 * cancel packet (design 5D): only legal inside on packet handlers (checker
 * enforced); sets the PlayerPacketEvent cancelled so vanilla handling is
 * skipped.
 */
public class CancelPacketStatement extends AbstractAstNode implements Statement {
    @Override
    public void execute(ExecutionContext context) {
        Object event = context.getVariables().get(PacketListeners.EVENT_VARIABLE);
        if (event instanceof PlayerPacketEvent packetEvent) {
            packetEvent.setCancelled(true);
        } else {
            System.err.println("Error: cancel packet outside an on packet handler");
        }
    }
}
