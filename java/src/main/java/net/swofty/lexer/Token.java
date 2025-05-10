package net.swofty.lexer;

/**
 * Represents a single token in the input
 */
public class Token {
    private final net.swofty.lexer.TokenType type;
    private final String value;
    private final int line;
    private final int column;

    public Token(net.swofty.lexer.TokenType type, String value, int line, int column) {
        this.type = type;
        this.value = value;
        this.line = line;
        this.column = column;
    }

    public net.swofty.lexer.TokenType getType() {
        return type;
    }

    public String getValue() {
        return value;
    }

    public int getLine() {
        return line;
    }

    public int getColumn() {
        return column;
    }

    @Override
    public String toString() {
        return String.format("Token{%s, '%s', line=%d, col=%d}", type, value, line, column);
    }
}
