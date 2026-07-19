package net.swofty.nativebridge.execution.expressions;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

public class UnaryExpression extends AbstractAstNode implements Expression {
    public enum Op {
        NOT,
        NEGATE,
        EXISTS
    }

    private final Op op;
    private final Expression operand;

    public UnaryExpression(Op op, Expression operand) {
        this.op = op;
        this.operand = operand;
    }

    public Op getOp() {
        return op;
    }

    public Expression getOperand() {
        return operand;
    }

    /**
     * Evaluate a unary expression
     */
    @Override
    public Object evaluate(ExecutionContext context) {
        Object value = context.evaluate(operand);

        switch (op) {
            case NOT:
                return !Values.toBoolean(value);
            case EXISTS:
                return !NoneValue.isNone(value);
            case NEGATE:
                if (value instanceof Integer) {
                    return -((Integer) value);
                }
                if (value instanceof Number) {
                    return -((Number) value).doubleValue();
                }
                System.err.println("Error: Cannot negate non-numeric value: " + value);
                return 0;
            default:
                throw new RuntimeException("Unknown unary operator: " + op);
        }
    }
}
