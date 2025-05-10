package net.swofty.nativebridge.execution.expressions;

import net.swofty.nativebridge.execution.Expression;

public class VariableReference implements Expression {
    private final String name;

    public VariableReference(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }
}
