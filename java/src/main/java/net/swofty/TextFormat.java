package net.swofty;

import java.util.Map;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.minimessage.MiniMessage;
import net.kyori.adventure.text.serializer.plain.PlainTextComponentSerializer;

/**
 * String to Component conversion: MiniMessage with a legacy-tag pre-map,
 * falling back to plain text when parsing fails.
 */
public final class TextFormat {
    private static final MiniMessage MINI_MESSAGE = MiniMessage.miniMessage();
    private static final Map<String, String> LEGACY_TAGS = Map.of(
            "<lime>", "<green>");

    private TextFormat() {
    }

    public static Component component(String text) {
        String mapped = text;
        for (Map.Entry<String, String> entry : LEGACY_TAGS.entrySet()) {
            mapped = mapped.replace(entry.getKey(), entry.getValue());
        }
        try {
            return MINI_MESSAGE.deserialize(mapped);
        } catch (Exception e) {
            return Component.text(text);
        }
    }

    public static String plain(Component component) {
        return PlainTextComponentSerializer.plainText().serialize(component);
    }
}
