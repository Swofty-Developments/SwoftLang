package net.swofty.nativebridge.execution.expressions;

import net.swofty.gui.GuiItems;
import net.swofty.model.ItemSpecModel;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ExecutionContext;

/**
 * Named-argument item(...) form in gui fill/border positions; the OCaml
 * emitter lowers it to a bare ItemSpec object (no "kind"), which the loader
 * wraps in this expression. Evaluates to an ItemStack via the GUI item
 * builder.
 */
public class ItemSpecExpression extends AbstractAstNode implements Expression {
    private final ItemSpecModel spec;

    public ItemSpecExpression(ItemSpecModel spec) {
        this.spec = spec;
    }

    public ItemSpecModel getSpec() {
        return spec;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        return GuiItems.build(spec, context.getExecutor());
    }
}
