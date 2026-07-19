package net.swofty.runtime;

import java.util.ArrayList;
import java.util.List;

import net.kyori.adventure.identity.Identity;
import net.minestom.server.command.CommandSender;
import net.minestom.server.tag.TagHandler;
import org.jetbrains.annotations.NotNull;

/**
 * Sender used for script blocks that have no natural player context (item
 * lore assembly, mob handlers, packet listeners without a player). Messages
 * go to stdout; a capturing instance can be used by harnesses.
 */
public final class SystemSender implements CommandSender {
    public static final SystemSender INSTANCE = new SystemSender(false);

    private final boolean capture;
    private final List<String> messages = new ArrayList<>();

    public SystemSender(boolean capture) {
        this.capture = capture;
    }

    @Override
    public void sendMessage(String message) {
        if (capture) {
            messages.add(message);
        } else {
            System.out.println("[script] " + message);
        }
    }

    /**
     * Component sends (the send statement renders MiniMessage now) capture /
     * print their plain-text projection, so mob/lore/packet handlers with no
     * player context keep working instead of dropping into the no-op default.
     */
    @Override
    public void sendMessage(net.kyori.adventure.text.Component message) {
        sendMessage(net.swofty.TextFormat.plain(message));
    }

    public List<String> getMessages() {
        return messages;
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
        return "System";
    }
}
