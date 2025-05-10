package net.swofty.nativebridge.execution.expressions;

import net.swofty.nativebridge.execution.Expression;

public class BinaryExpression implements Expression {
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
        IS_NOT_TYPE("is not");

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
}