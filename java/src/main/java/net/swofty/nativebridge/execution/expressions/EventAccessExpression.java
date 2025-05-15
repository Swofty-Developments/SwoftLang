package net.swofty.nativebridge.execution.expressions;

import net.swofty.nativebridge.execution.Expression;

public class EventAccessExpression implements Expression {
    private String property;

    public EventAccessExpression(String property) {
        this.property = property;
    }

    public String getProperty() {
        return property;
    }
}
