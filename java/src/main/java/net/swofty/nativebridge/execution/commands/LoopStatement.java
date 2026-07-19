package net.swofty.nativebridge.execution.commands;

import java.util.Map;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

public class LoopStatement extends AbstractAstNode implements Statement {
    private final Expression count;
    private final String variable;
    private final Statement body;

    public LoopStatement(Expression count, String variable, Statement body) {
        this.count = count;
        this.variable = variable;
        this.body = body;
    }

    public Expression getCount() {
        return count;
    }

    public String getVariable() {
        return variable;
    }

    public Statement getBody() {
        return body;
    }

    /**
     * Execute a loop statement (loop N times [as var])
     */
    @Override
    public void execute(ExecutionContext context) {
        Object countValue = context.evaluate(count);
        if (!(countValue instanceof Number)) {
            System.err.println("Error: Loop count is not a number: " + countValue);
            return;
        }

        int times = ((Number) countValue).intValue();
        if (variable == null) {
            for (int i = 1; i <= times; i++) {
                context.execute(body);
            }
            return;
        }

        // the loop variable is scoped to the loop: any outer binding is
        // restored afterwards, matching the typechecker's restore_binding
        Map<String, Object> variables = context.getVariables();
        boolean hadOuter = variables.containsKey(variable);
        Object outer = variables.get(variable);
        try {
            for (int i = 1; i <= times; i++) {
                variables.put(variable, i);
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
}
