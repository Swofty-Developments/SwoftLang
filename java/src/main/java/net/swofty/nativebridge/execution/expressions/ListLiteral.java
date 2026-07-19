package net.swofty.nativebridge.execution.expressions;

import java.util.ArrayList;
import java.util.List;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ExecutionContext;

public class ListLiteral extends AbstractAstNode implements Expression {
    private final List<Expression> items;

    public ListLiteral(List<Expression> items) {
        this.items = items;
    }

    public List<Expression> getItems() {
        return items;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        List<Object> values = new ArrayList<>();
        for (Expression item : items) {
            values.add(context.evaluate(item));
        }
        return values;
    }
}
