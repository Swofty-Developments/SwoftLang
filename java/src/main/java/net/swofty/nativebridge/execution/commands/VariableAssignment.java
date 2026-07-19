package net.swofty.nativebridge.execution.commands;

import java.util.List;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.PathResolver;
import net.swofty.runtime.ExecutionContext;

public class VariableAssignment extends AbstractAstNode implements Statement {
    private final String variableName;
    private final Expression value;

    public VariableAssignment(String variableName, Expression value) {
        this.variableName = variableName;
        this.value = value;
    }

    public String getVariableName() {
        return variableName;
    }

    public Expression getValue() {
        return value;
    }

    /**
     * Execute a variable assignment; dotted targets (schema v1) route
     * through the shared PathResolver
     */
    @Override
    public void execute(ExecutionContext context) {
        Object evaluated = context.evaluate(value);

        if (variableName.contains(".")) {
            String[] parts = variableName.split("\\.");
            List<String> hops = List.of(parts).subList(1, parts.length);
            PathResolver.assignVariablePath(context.getVariables(), parts[0], hops,
                    evaluated, -1, -1);
        } else {
            context.getVariables().put(variableName, evaluated);
        }
    }
}
