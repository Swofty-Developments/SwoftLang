package net.swofty.nativebridge.execution.expressions;

import java.util.LinkedHashMap;
import java.util.Map;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.MapValue;

/**
 * { key: expr, ... } object literal - used both for script-level map
 * literals (design phase-10 §1) and nested packet payloads (design 5D).
 * Evaluates to an insertion-ordered {@link MapValue}, which is a
 * java.util.Map and so flows unchanged through every generic map consumer.
 */
public class ObjectLiteralExpression extends AbstractAstNode implements Expression {
    // Keys are String OR Integer (design phase-11 int map keys). Integer-keyed
    // literals must box their keys as Integer so they match the Integer keys
    // map_set / index-assign produce (via Values.coerceMapKey) — otherwise a
    // literal key "1" (String) and a mutated key 1 (Integer) collide as two
    // distinct LinkedHashMap entries. Packet/nested-object payloads keep String
    // field names; both flow through the same Object-keyed store.
    private final Map<Object, Expression> fields;

    public ObjectLiteralExpression(Map<?, Expression> fields) {
        this.fields = new LinkedHashMap<>(fields);
    }

    public Map<Object, Expression> getFields() {
        return fields;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        MapValue values = new MapValue();
        for (Map.Entry<Object, Expression> entry : fields.entrySet()) {
            values.put(entry.getKey(), context.evaluate(entry.getValue()));
        }
        return values;
    }
}
