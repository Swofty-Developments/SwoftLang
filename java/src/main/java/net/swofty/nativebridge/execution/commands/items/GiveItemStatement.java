package net.swofty.nativebridge.execution.commands.items;

import net.minestom.server.entity.Player;
import net.swofty.items.ItemRegistry;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * give item "id" to &lt;player&gt; [amount N] (design 5A)
 */
public class GiveItemStatement extends AbstractAstNode implements Statement {
    private final Expression itemId;
    private final Expression target;
    private final Expression amount;

    public GiveItemStatement(Expression itemId, Expression target, Expression amount) {
        this.itemId = itemId;
        this.target = target;
        this.amount = amount;
    }

    @Override
    public void execute(ExecutionContext context) {
        String id = (String) Coercions.toStringValue(context.evaluate(itemId));
        Object resolved = context.evaluate(target);
        // 0 = "use the declared default amount" (phase 9 amount: field)
        int count = amount != null
                ? Coercions.requireNumber(context.evaluate(amount), "give amount").intValue()
                : 0;
        if (resolved instanceof Player player) {
            ItemRegistry.give(player, id, count);
        } else if (resolved instanceof java.util.Collection<?> collection) {
            for (Object element : collection) {
                if (element instanceof Player player) {
                    ItemRegistry.give(player, id, count);
                }
            }
        } else {
            throw new net.swofty.ScriptError("give item expects a player, got: "
                    + Values.displayString(resolved));
        }
    }
}
