package net.swofty.execution.expressions;

import net.swofty.execution.Expression;

public class VariableReference implements Expression {
    private final String name;

    public VariableReference(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }
}
