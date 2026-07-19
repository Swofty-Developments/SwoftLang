package net.swofty.items;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.TextDecoration;
import net.swofty.ASTExecutor;
import net.swofty.TextFormat;
import net.swofty.model.ItemDefModel;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.nativebridge.execution.commands.ui.LineStatement;
import net.swofty.runtime.SystemSender;

/**
 * WYSIWYG name + lore rendering (phase 9). The Hypixel lore pipeline
 * (stat lines, ability blocks, rarity banners, symbol tables) is gone:
 * the display name is exactly the declared name, and the lore is exactly
 * the lore{} lines the script wrote. MiniMessage is converted at build;
 * legacy &amp;/&sect; codes pass through. Italic is forced off so item text
 * renders like a normal tooltip rather than vanilla's italic custom name.
 */
public final class ItemLoreBuilder {
    private static final Pattern MINI_MESSAGE_TAG =
            Pattern.compile("<[a-zA-Z#][a-zA-Z0-9#_:/'\",.-]*>");

    private ItemLoreBuilder() {
    }

    /** The declared display name, MiniMessage converted, italics off. */
    public static Component buildName(ItemDefModel def) {
        String name = def.name() != null ? def.name() : def.id();
        return line(name);
    }

    /**
     * The lore{} block rendered exactly as written: a restricted execute
     * block of line/blank statements (if/loop allowed) run serverless. Tag
     * values feed the environment so lines may interpolate ${tags.x}.
     */
    public static List<Component> buildLore(ItemDefModel def, Map<String, Object> tagValues) {
        if (def.lore() == null || def.lore().isEmpty()) {
            return List.of();
        }
        LoreCollector collector = new LoreCollector(def, tagValues);
        collector.execute(def.lore());
        return collector.lines;
    }

    /** One rendered lore/name line: MiniMessage converted, italics forced off. */
    private static Component line(String text) {
        return TextFormat.component(text).decoration(TextDecoration.ITALIC, false);
    }

    /** Collecting executor for lore bodies: line/blank emit, if/loop run. */
    private static final class LoreCollector extends ASTExecutor {
        private final List<Component> lines = new ArrayList<>();

        LoreCollector(ItemDefModel def, Map<String, Object> tagValues) {
            super(SystemSender.INSTANCE, initialVars(def, tagValues));
        }

        private static Map<String, Object> initialVars(ItemDefModel def,
                Map<String, Object> tagValues) {
            Map<String, Object> vars = new HashMap<>();
            vars.put("item_id", def.id());
            vars.put("tags", tagValues);
            return vars;
        }

        @Override
        protected void emitUi(Statement statement) {
            if (statement instanceof LineStatement lineStatement) {
                if (lineStatement.isBlank()) {
                    lines.add(Component.empty());
                    return;
                }
                lines.add(line(evaluateStringExpression(lineStatement.getText())));
            }
        }
    }

    public static boolean isMiniMessage(String text) {
        return text != null && MINI_MESSAGE_TAG.matcher(text).find();
    }
}
