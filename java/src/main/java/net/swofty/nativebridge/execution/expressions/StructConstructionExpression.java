package net.swofty.nativebridge.execution.expressions;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import net.swofty.ScriptError;
import net.swofty.model.StructDefModel;
import net.swofty.model.StructFieldModel;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ExecutionContext;
import net.swofty.structs.StructRegistry;
import net.swofty.structs.StructValue;

/**
 * {@code Guild { name: "Knights", ... }} struct construction (§1.2). Totality:
 * every field of the declaration ends up present — a field the constructor
 * supplies takes the supplied value, and a field it omits takes the struct's
 * declared default (the typechecker guarantees no non-default field is omitted).
 * The resulting field map is built in declaration order so it is stable and
 * matches the persistence serialization order.
 */
public class StructConstructionExpression extends AbstractAstNode implements Expression {
    /** A supplied field: its name and the expression for its value. */
    public record FieldInit(String name, Expression value) {
    }

    private final String structName;
    private final List<FieldInit> supplied;

    public StructConstructionExpression(String structName, List<FieldInit> supplied) {
        this.structName = structName;
        this.supplied = supplied;
    }

    public String getStructName() {
        return structName;
    }

    public List<FieldInit> getSupplied() {
        return supplied;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        StructDefModel def = StructRegistry.get(structName);
        if (def == null) {
            throw new ScriptError("unknown struct type '" + structName + "'", getLine(), getCol());
        }

        // index the supplied values by field name for order-independent lookup
        Map<String, Expression> byName = new LinkedHashMap<>();
        for (FieldInit init : supplied) {
            byName.put(init.name(), init.value());
        }

        LinkedHashMap<String, Object> values = new LinkedHashMap<>();
        for (StructFieldModel field : def.fields()) {
            Expression expr = byName.get(field.name());
            if (expr == null) {
                expr = field.defaultValue();
            }
            if (expr == null) {
                // typechecker should have caught this; guard so we never build a
                // half-formed instance (totality, §1.2)
                throw new ScriptError("struct '" + structName + "' construction is missing field '"
                        + field.name() + "'", getLine(), getCol());
            }
            values.put(field.name(), context.evaluate(expr));
        }
        return new StructValue(structName, values);
    }
}
