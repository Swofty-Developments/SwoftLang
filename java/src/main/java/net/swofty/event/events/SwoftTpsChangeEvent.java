package net.swofty.event.events;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.nativebridge.representation.Event;
import net.swofty.runtime.SystemSender;
import net.swofty.tps.TpsChangeEvent;

/**
 * event TpsChange { past, current, tps } wrapper (design 6B): fired on
 * integer TPS bucket changes; there is no player context, so the sender
 * is the console.
 */
public class SwoftTpsChangeEvent extends AbstractSwoftEvent<TpsChangeEvent> {
    public SwoftTpsChangeEvent(TpsChangeEvent minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
    }

    public int getPast() {
        return minestomEvent.getPast();
    }

    public int getCurrent() {
        return minestomEvent.getCurrent();
    }

    public double getTps() {
        return minestomEvent.getTps();
    }

    @Override
    public CommandSender getSender() {
        try {
            return MinecraftServer.getCommandManager().getConsoleSender();
        } catch (Throwable t) {
            return SystemSender.INSTANCE;
        }
    }
}
