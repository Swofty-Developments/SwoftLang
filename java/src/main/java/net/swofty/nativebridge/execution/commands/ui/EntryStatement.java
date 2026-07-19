package net.swofty.nativebridge.execution.commands.ui;

import net.swofty.model.SkinSpecModel;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * entry "text" with skin s inside a tablist column; null text = fill
 */
public class EntryStatement extends AbstractAstNode implements Statement {
    private final Expression text;
    private final SkinSpecModel skin;

    public EntryStatement(Expression text, SkinSpecModel skin) {
        this.text = text;
        this.skin = skin;
    }

    public Expression getText() {
        return text;
    }

    public SkinSpecModel getSkin() {
        return skin;
    }

    public boolean isFill() {
        return text == null;
    }

    @Override
    public void execute(ExecutionContext context) {
        context.emitUi(this);
    }
}
