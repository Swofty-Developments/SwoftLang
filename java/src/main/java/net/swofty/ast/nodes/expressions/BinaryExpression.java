package net.swofty.ast.nodes.expressions;

import net.swofty.ast.ASTVisitor;
import net.swofty.ast.nodes.Expression;

/**
 * Binary expression (for conditions)
 */
public class BinaryExpression implements Expression {
    public enum Operator {
        EQUALS("=="),
        NOT_EQUALS("!="),
        LESS_THAN("<"),
        GREATER_THAN(">"),
        LESS_THAN_EQUALS("<="),
        GREATER_THAN_EQUALS(">="),
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

        public static Operator fromString(String symbol) {
            for (Operator op : values()) {
                if (op.symbol.equals(symbol)) {
                    return op;
                }
            }
            return null;
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

    @Override
    public void accept(ASTVisitor visitor) {
        visitor.visit(this);
    }
}
