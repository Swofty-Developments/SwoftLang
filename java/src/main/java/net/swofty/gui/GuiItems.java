package net.swofty.gui;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.TextDecoration;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.PlayerSkin;
import net.minestom.server.component.DataComponents;
import net.minestom.server.item.ItemStack;
import net.minestom.server.item.Material;
import net.minestom.server.network.player.ResolvableProfile;
import net.swofty.ASTExecutor;
import net.swofty.ScriptError;
import net.swofty.TextFormat;
import net.swofty.model.ItemSpecModel;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.props.Coercions;
import net.swofty.props.NoneValue;

/**
 * Builds Minestom ItemStacks from item { ... } specs. Sub-expressions are
 * evaluated through the caller's executor so state/player/item bindings
 * apply; names and lore go through MiniMessage with italic stripped.
 */
public final class GuiItems {
    private GuiItems() {
    }

    public static ItemStack build(ItemSpecModel spec, ASTExecutor executor) {
        ItemStack.Builder builder;
        if (spec.skull() != null) {
            builder = ItemStack.builder(Material.PLAYER_HEAD)
                    .set(DataComponents.PROFILE, profile(executor.evaluateExpression(spec.skull())));
        } else if (spec.material() != null) {
            builder = ItemStack.builder(Coercions.toMaterial(executor.evaluateExpression(spec.material())));
        } else {
            throw new ScriptError("item spec needs a material or a skull");
        }

        if (spec.name() != null) {
            builder.set(DataComponents.CUSTOM_NAME, component(executor, spec.name()));
        }
        if (spec.lore() != null) {
            List<Component> lore = new ArrayList<>(spec.lore().size());
            for (Expression line : spec.lore()) {
                lore.add(component(executor, line));
            }
            builder.set(DataComponents.LORE, lore);
        }
        if (spec.amount() != null) {
            builder.amount((Integer) Coercions.toItemAmount(executor.evaluateExpression(spec.amount())));
        }
        if (spec.glint() != null) {
            Object glint = executor.evaluateExpression(spec.glint());
            builder.glowing(!NoneValue.isNone(glint) && (Boolean) Coercions.toBoolean(glint));
        }
        return builder.build();
    }

    /**
     * String → Component with the reference frameworks' italic strip so gui
     * items don't render in default italics
     */
    public static Component component(ASTExecutor executor, Expression expression) {
        Object value = executor.evaluateExpression(expression);
        Component component = value instanceof Component c
                ? c
                : TextFormat.component(NoneValue.isNone(value) ? "" : executor.getDisplayString(value));
        return component.decorationIfAbsent(TextDecoration.ITALIC, TextDecoration.State.FALSE);
    }

    /**
     * Skull value: a Player uses their live skin; a String is either a full
     * base64 profile blob or a bare texture hash wrapped in the standard
     * profile JSON (gui.md §1.5 mechanism)
     */
    private static ResolvableProfile profile(Object value) {
        if (value instanceof Player player) {
            PlayerSkin skin = player.getSkin();
            return skin != null ? new ResolvableProfile(skin) : ResolvableProfile.EMPTY;
        }
        String texture = (String) Coercions.toStringValue(value);
        String encoded = texture.startsWith("ey")
                ? texture
                : Base64.getEncoder().encodeToString(
                        ("{\"textures\":{\"SKIN\":{\"url\":\"http://textures.minecraft.net/texture/"
                                + texture + "\"}}}").getBytes(StandardCharsets.UTF_8));
        return new ResolvableProfile(new PlayerSkin(encoded, null));
    }
}
