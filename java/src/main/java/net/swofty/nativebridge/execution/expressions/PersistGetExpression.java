package net.swofty.nativebridge.execution.expressions;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ExecutionContext;

/**
 * Read of a persistent variable: {"kind":"persist_get","name","subject"}.
 * subject is null for global scalars, otherwise the keyed-access
 * expression (kills for event.player).
 *
 * <p>Under {@code mode: network} (1.10.0 §3.1) one case is not a cache read: a
 * session-owned row whose lease belongs to ANOTHER server. The cache holds
 * nothing for it, so a plain read would silently answer with the declared
 * default. That case yields a {@code Future<T>} over an IO snapshot instead, and
 * the compiler has already required the {@code await} that consumes it.
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
        net.swofty.persist.PersistStore store = context.persistStore();
        String key = context.persistKey(name, subject);
        if (store != null && store.isRemoteSession(name, key)) {
            return new net.swofty.async.FutureValue(store.readRemote(name, key));
        }
        return store.get(name, key);
    }
}
