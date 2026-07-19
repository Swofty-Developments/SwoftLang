package net.swofty.nativebridge.execution.expressions;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

public class BinaryExpression extends AbstractAstNode implements Expression {
    public enum Operator {
        EQUALS("=="),
        NOT_EQUALS("!="),
        LESS_THAN("<"),
        GREATER_THAN(">"),
        LESS_EQUALS("<="),
        GREATER_EQUALS(">="),
        AND("&&"),
        OR("||"),
        IS_TYPE("is"),
        IS_NOT_TYPE("is not"),
        CONTAINS("contains"),
        OR_ELSE("otherwise"),
        CONCATENATE("+"),
        ADD("+"),
        SUBTRACT("-"),
        MULTIPLY("*"),
        DIVIDE("/"),
        MODULO("%");

        private final String symbol;

        Operator(String symbol) {
            this.symbol = symbol;
        }

        public String getSymbol() {
            return symbol;
        }
    }

    private final Expression left;
    private final Operator operator;
    private final Expression right;

    public BinaryExpression(Expression left, Operator operator, Expression right) {
        this.left = left;
        this.operator = operator;
        this.right = right;
    }

    public Expression getLeft() {
        return left;
    }

    public Operator getOperator() {
        return operator;
    }

    public Expression getRight() {
        return right;
    }

    /**
     * Evaluate a binary expression
     */
    @Override
    public Object evaluate(ExecutionContext context) {
        // otherwise: lazy right-hand evaluation
        if (operator == Operator.OR_ELSE) {
            Object left = context.evaluate(this.left);
            return NoneValue.isNone(left) ? context.evaluate(right) : left;
        }

        Object left = context.evaluate(this.left);
        Object right = context.evaluate(this.right);

        switch (operator) {
            case EQUALS:
                return Values.objectsEqual(left, right);
            case NOT_EQUALS:
                return !Values.objectsEqual(left, right);
            case LESS_THAN:
                return Values.compareObjects(left, right) < 0;
            case GREATER_THAN:
                return Values.compareObjects(left, right) > 0;
            case LESS_EQUALS:
                return Values.compareObjects(left, right) <= 0;
            case GREATER_EQUALS:
                return Values.compareObjects(left, right) >= 0;
            case AND:
                return Values.toBoolean(left) && Values.toBoolean(right);
            case OR:
                return Values.toBoolean(left) || Values.toBoolean(right);
            case IS_TYPE:
                return Values.isType(left, (String) right);
            case IS_NOT_TYPE:
                return !Values.isType(left, (String) right);
            case CONTAINS:
            {
                if (left == NoneValue.INSTANCE) {
                    left = null;
                }
                if (right == NoneValue.INSTANCE) {
                    right = null;
                }
                // Debug logging to inspect operands
                System.out.println("CONTAINS check - Left: '" + left + "' (" +
                        (left != null ? left.getClass().getName() : "null") +
                        "), Right: '" + right + "' (" +
                        (right != null ? right.getClass().getName() : "null") + ")");

                // Convert both operands to lowercase strings for case-insensitive comparison
                String leftStr = left != null ? Values.displayString(left).toLowerCase() : "";
                String rightStr = right != null ? Values.displayString(right).toLowerCase() : "";

                // Check if leftStr contains rightStr
                boolean result = leftStr.contains(rightStr);
                System.out.println("CONTAINS result: " + result + " (checking if '" +
                        leftStr + "' contains '" + rightStr + "')");
                return result;
            }

            case CONCATENATE:
                {
                    // Interpolation-style concatenation: none renders as ""
                    String leftStr = NoneValue.isNone(left) ? "" : Values.displayString(left);
                    String rightStr = NoneValue.isNone(right) ? "" : Values.displayString(right);
                    return leftStr + rightStr;
                }
            case ADD:
                if (left instanceof Number && right instanceof Number) {
                    return arithmetic(left, right, operator);
                }
                // Non-numeric + falls back to string concatenation
                return Values.displayString(left) + Values.displayString(right);
            case SUBTRACT:
            case MULTIPLY:
            case DIVIDE:
            case MODULO:
                if (left instanceof Number && right instanceof Number) {
                    return arithmetic(left, right, operator);
                }
                System.err.println("Error: Cannot apply " + operator + " to non-numeric values: " +
                        left + ", " + right);
                return 0;
            default:
                throw new RuntimeException("Unknown operator: " + operator);
        }
    }

    /**
     * Numeric arithmetic; Integer when both operands are Integers, Double otherwise
     */
    private static Object arithmetic(Object left, Object right, Operator operator) {
        Number leftNum = (Number) left;
        Number rightNum = (Number) right;

        if ((operator == Operator.DIVIDE || operator == Operator.MODULO)
                && rightNum.doubleValue() == 0) {
            System.err.println("Error: Division by zero");
            return 0;
        }

        if (left instanceof Integer && right instanceof Integer) {
            int l = leftNum.intValue();
            int r = rightNum.intValue();
            switch (operator) {
                case ADD: return l + r;
                case SUBTRACT: return l - r;
                case MULTIPLY: return l * r;
                case DIVIDE: return l / r;
                case MODULO: return l % r;
                default: throw new RuntimeException("Unknown arithmetic operator: " + operator);
            }
        }

        double l = leftNum.doubleValue();
        double r = rightNum.doubleValue();
        switch (operator) {
            case ADD: return l + r;
            case SUBTRACT: return l - r;
            case MULTIPLY: return l * r;
            case DIVIDE: return l / r;
            case MODULO: return l % r;
            default: throw new RuntimeException("Unknown arithmetic operator: " + operator);
        }
    }
}
