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
     * Component sends (the send/broadcast statement renders MiniMessage to a
     * Component now) must forward to the wrapped sender - the default Audience
     * method is a no-op, which would silently swallow every scripted send.
     */
    @Override
    public void sendMessage(net.kyori.adventure.text.Component message) {
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

    @Override
    public String toString() {
        if (getMinestomSender() instanceof Player) {
            return ((Player) getMinestomSender()).getUsername();
        }
        return "Console";
    }
}