package net.swofty.nativebridge.execution.commands;

import java.util.Collection;
import java.util.Map;

import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * loop [first N of] <iterable> as <var>; limit is null when no bound was
 * declared. With a valueVariable ({@code loop m as key -> value}) the
 * iterable is a map and each entry binds key + value (design phase-10 §1).
 */
public class ForEachStatement extends AbstractAstNode implements Statement {
    private final String variable;
    private final String valueVariable;
    private final Expression iterable;
    private final Expression limit;
    private final Statement body;

    public ForEachStatement(String variable, Expression iterable, Expression limit, Statement body) {
        this(variable, null, iterable, limit, body);
    }

    public ForEachStatement(String variable, String valueVariable, Expression iterable,
            Expression limit, Statement body) {
        this.variable = variable;
        this.valueVariable = valueVariable;
        this.iterable = iterable;
        this.limit = limit;
        this.body = body;
    }

    public String getVariable() {
        return variable;
    }

    public String getValueVariable() {
        return valueVariable;
    }

    public Expression getIterable() {
        return iterable;
    }

    public Expression getLimit() {
        return limit;
    }

    public Statement getBody() {
        return body;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object iterableValue = context.evaluate(iterable);

        long bound = Long.MAX_VALUE;
        if (limit != null) {
            Object limitValue = context.evaluate(limit);
            if (!(limitValue instanceof Number)) {
                throw new ScriptError("loop first expects a number, got: "
                        + Values.displayString(limitValue));
            }
            bound = ((Number) limitValue).longValue();
        }

        // map iteration: loop m as key [-> value]. A snapshot of the entries
        // lets the body mutate the map without ConcurrentModification.
        if (iterableValue instanceof Map<?, ?> mapValue) {
            java.util.List<Map.Entry<?, ?>> entries =
                    new java.util.ArrayList<>(mapValue.entrySet());
            iterateMap(context, entries, bound);
            return;
        }

        if (!(iterableValue instanceof Collection)) {
            System.err.println("Error: Cannot iterate over non-collection value: " + iterableValue);
            return;
        }

        // the loop variable is scoped to the loop: any outer binding is
        // restored afterwards, matching the typechecker's restore_binding
        Map<String, Object> variables = context.getVariables();
        boolean hadOuter = variables.containsKey(variable);
        Object outer = variables.get(variable);
        try {
            long seen = 0;
            for (Object element : (Collection<?>) iterableValue) {
                if (seen++ >= bound) {
                    break;
                }
                variables.put(variable, element);
                context.execute(body);
            }
        } finally {
            if (hadOuter) {
                variables.put(variable, outer);
            } else {
                variables.remove(variable);
            }
        }
    }

    private void iterateMap(ExecutionContext context,
            java.util.List<Map.Entry<?, ?>> entries, long bound) {
        Map<String, Object> variables = context.getVariables();
        boolean hadKey = variables.containsKey(variable);
        Object outerKey = variables.get(variable);
        boolean hasValueBinder = valueVariable != null;
        boolean hadValue = hasValueBinder && variables.containsKey(valueVariable);
        Object outerValue = hasValueBinder ? variables.get(valueVariable) : null;
        try {
            long seen = 0;
            for (Map.Entry<?, ?> entry : entries) {
                if (seen++ >= bound) {
                    break;
                }
                variables.put(variable, entry.getKey());
                if (hasValueBinder) {
                    variables.put(valueVariable, entry.getValue());
                }
                context.execute(body);
            }
        } finally {
            if (hadKey) {
                variables.put(variable, outerKey);
            } else {
                variables.remove(variable);
            }
            if (hasValueBinder) {
                if (hadValue) {
                    variables.put(valueVariable, outerValue);
                } else {
                    variables.remove(valueVariable);
                }
            }
        }
    }
}
