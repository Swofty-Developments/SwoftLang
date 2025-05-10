package net.swofty.command;

import net.kyori.adventure.identity.Identity;
import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.minestom.server.tag.TagHandler;
import org.jetbrains.annotations.NotNull;

/**
 * Adapter that wraps a Minestom CommandSender for use with SwoftLang
 */
public class MinestomSenderAdapter implements CommandSender {
    private final net.minestom.server.command.CommandSender minestomSender;

    public MinestomSenderAdapter(net.minestom.server.command.CommandSender minestomSender) {
        this.minestomSender = minestomSender;
    }

    @Override
    public void sendMessage(String message) {
        minestomSender.sendMessage(message);
    }

    /**
     * Get the wrapped Minestom sender
     * @return The underlying Minestom CommandSender
     */
    public net.minestom.server.command.CommandSender getMinestomSender() {
        return minestomSender;
    }

    @Override
    public @NotNull Identity identity() {
        return Identity.nil();
    }

    @Override
    public @NotNull TagHandler tagHandler() {
        return TagHandler.newHandler();
    }
}