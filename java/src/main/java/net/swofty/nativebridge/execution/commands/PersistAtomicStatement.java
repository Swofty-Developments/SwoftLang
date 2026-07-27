package net.swofty.nativebridge.execution.commands;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * Atomic write to a persistent value (design 1.10.0 §3.2):
 * {"kind":"persist_atomic","op","mutation","name","subject","key","value"}.
 *
 * <p>Emitted only under {@code mode: network} — in {@code mode: standalone} the
 * compiler emits the plain local desugaring this surface has always had, so an
 * unchanged program never produces this node and never reaches this class.
 *
 * <p>{@code op} is the surface spelling as written ({@code add} / {@code
 * subtract} / {@code append} / {@code set_at}); {@code mutation} is the
 * typechecker's refinement of it against the declared value type ({@code
 * increment} / {@code decrement} / {@code append} / {@code put}), which is what
 * separates {@code add x to some_list} from {@code add 50 to pot}. The
 * refinement wins when it resolves, because it is the one that consulted the
 * declared type.
 */
public class PersistAtomicStatement extends AbstractAstNode implements Statement {
    private final String op;
    private final String mutation;
    private final String name;
    private final Expression subject;
    private final Expression key;
    private final Expression value;

    public PersistAtomicStatement(String op, String mutation, String name, Expression subject,
            Expression key, Expression value) {
        this.op = op;
        this.mutation = mutation;
        this.name = name;
        this.subject = subject;
        this.key = key;
        this.value = value;
    }

    public String getOp() {
        return op;
    }

    public String getMutation() {
        return mutation;
    }

    public String getName() {
        return name;
    }

    public Expression getSubject() {
        return subject;
    }

    public Expression getKey() {
        return key;
    }

    public Expression getValue() {
        return value;
    }

    /** The op name to apply: the refined mutation when it resolves, else the surface op. */
    public String effectiveOp() {
        return net.swofty.persist.network.AtomicOp.parse(mutation) != null ? mutation : op;
    }

    @Override
    public void execute(ExecutionContext context) {
        context.persistStore().atomic(effectiveOp(), name,
                context.persistKey(name, subject), context.evaluate(value),
                key == null ? null : context.evaluate(key));
    }
}
