package net.swofty.model;

import java.util.List;
import java.util.Map;

import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * One item "id" { } declaration reduced to the generic core (phase 9).
 * material XOR skull; the name/rarity/glint drive appearance only; lore is
 * a restricted execute block of line/blank statements (WYSIWYG, if/loop
 * allowed) with no auto-assembled sections; attributes are real vanilla
 * Minestom attributes; tags carry arbitrary nested NBT (scalars, lists,
 * compounds) in declaration order; on_click handlers are filtered
 * PlayerUseItem sugar. stats{}/ability{} were removed — gameplay systems
 * are built in userland with event handlers (see addons/abilities.sw).
 */
public record ItemDefModel(
        String id,
        String material,
        String skull,
        String name,
        String rarity,
        boolean glint,
        int amount,
        ExecuteBlock lore,
        Map<String, Double> attributes,
        Map<String, Object> tags,
        List<ItemClickHandlerModel> onClick,
        Map<String, InlineHandler> handlers,
        String typeName) {

    /** Pre-inline-handlers shape, kept for existing call sites/smoke tests. */
    public ItemDefModel(String id, String material, String skull, String name,
            String rarity, boolean glint, int amount, ExecuteBlock lore,
            Map<String, Double> attributes, Map<String, Object> tags,
            List<ItemClickHandlerModel> onClick) {
        // legacy/back-compat callers have no nominal type name; the id doubles
        // as the type name so 'is a <id>' still resolves
        this(id, material, skull, name, rarity, glint, amount, lore,
                attributes, tags, onClick, Map.of(), id);
    }

    /** The generic first-class handler for {@code event}, or null. */
    public InlineHandler handler(String event) {
        return handlers == null ? null : handlers.get(event);
    }
}
