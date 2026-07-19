package net.swofty.nativebridge.execution.commands;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * Write of a persistent variable:
 * {"kind":"persist_set","name","subject","value"}. subject is null for
 * global scalars (set total_joins to ...), otherwise the keyed-access
 * expression (set kills for event.player to ...).
 */
public class PersistSetStatement extends AbstractAstNode implements Statement {
    private final String name;
    private final Expression subject;
    private final Expression value;

    public PersistSetStatement(String name, Expression subject, Expression value) {
        this.name = name;
        this.subject = subject;
        this.value = value;
    }

    public String getName() {
        return name;
    }

    public Expression getSubject() {
        return subject;
    }

    public Expression getValue() {
        return value;
    }

    @Override
    public void execute(ExecutionContext context) {
        context.persistStore().set(name, context.persistKey(name, subject),
                context.evaluate(value));
    }
}
