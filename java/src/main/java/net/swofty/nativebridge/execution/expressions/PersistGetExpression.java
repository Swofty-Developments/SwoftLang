package net.swofty.nativebridge.execution.expressions;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ExecutionContext;

/**
 * Read of a persistent variable: {"kind":"persist_get","name","subject"}.
 * subject is null for global scalars, otherwise the keyed-access
 * expression (kills for event.player).
 */
public class PersistGetExpression extends AbstractAstNode implements Expression {
    private final String name;
    private final Expression subject;

    public PersistGetExpression(String name, Expression subject) {
        this.name = name;
        this.subject = subject;
    }

    public String getName() {
        return name;
    }

    public Expression getSubject() {
        return subject;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        return context.persistStore().get(name, context.persistKey(name, subject));
    }
}
