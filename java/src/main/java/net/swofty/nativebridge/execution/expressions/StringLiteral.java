package net.swofty.nativebridge.execution.expressions;

import net.swofty.nativebridge.execution.Expression;

public class StringLiteral implements Expression {
    private final String value;

    public StringLiteral(String value) {
        this.value = value;
    }

    public String getValue() {
        return value;
    }
}