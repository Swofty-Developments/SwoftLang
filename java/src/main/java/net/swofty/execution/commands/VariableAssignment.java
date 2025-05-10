package net.swofty.execution.commands;

import net.swofty.execution.Expression;
import net.swofty.execution.Statement;

public class VariableAssignment implements Statement {
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
}
