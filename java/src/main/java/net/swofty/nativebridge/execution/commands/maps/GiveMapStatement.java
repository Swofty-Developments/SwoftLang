package net.swofty.nativebridge.execution.commands.maps;

import net.minestom.server.entity.Player;
import net.minestom.server.component.DataComponents;
import net.minestom.server.item.ItemStack;
import net.minestom.server.item.Material;
import net.swofty.maps.MapCanvas;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.PlayerTargets;

/**
 * give map of &lt;canvas&gt; to &lt;player&gt; (design 6D): a filled map item
 * bound to the canvas' allocated map id, plus the framebuffer packet so
 * it renders immediately (and on every later draw).
 */
public class GiveMapStatement extends AbstractAstNode implements Statement {
    private final Expression canvas;
    private final Expression target;

    public GiveMapStatement(Expression canvas, Expression target) {
        this.canvas = canvas;
        this.target = target;
    }

    @Override
    public void execute(ExecutionContext context) {
        MapCanvas resolved = DrawStatement.requireCanvas(
                context.evaluate(canvas), "give map");
        ItemStack map = ItemStack.of(Material.FILLED_MAP)
                .with(DataComponents.MAP_ID, resolved.mapId());
        for (Player player : PlayerTargets.resolve(context,
                target != null ? context.evaluate(target) : null, "give map")) {
            player.getInventory().addItemStack(map);
            resolved.addViewer(player);
        }
    }
}
