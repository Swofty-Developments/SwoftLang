package net.swofty.lexer;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Lexer for SwoftLang script
 */
public class SwoftLexer {
    private final String source;
    private int position;
    private int line;
    private int column;

    // Keywords map
    private static final Map<String, TokenType> KEYWORDS = new HashMap<>();
    static {
        KEYWORDS.put("if", TokenType.IF);
        KEYWORDS.put("else", TokenType.ELSE);
        KEYWORDS.put("halt", TokenType.HALT);
        KEYWORDS.put("send", TokenType.SEND);
        KEYWORDS.put("teleport", TokenType.TELEPORT);
        KEYWORDS.put("to", TokenType.TO);
        KEYWORDS.put("is", TokenType.IS);
        KEYWORDS.put("not", TokenType.NOT);
        KEYWORDS.put("a", TokenType.A);
    }

    public SwoftLexer(String source) {
        this.source = source;
        this.position = 0;
        this.line = 1;
        this.column = 1;
    }

    /**
     * Tokenize the entire input
     */
    public List<Token> tokenize() {
        List<Token> tokens = new ArrayList<>();

        while (position < source.length()) {
            Token token = nextToken();
            if (token.getType() != TokenType.UNKNOWN) {
                tokens.add(token);
            }

            if (token.getType() == TokenType.EOF) {
                break;
            }
        }

        // Ensure we always have an EOF token
        if (tokens.isEmpty() || tokens.getLast().getType() != TokenType.EOF) {
            tokens.add(new Token(TokenType.EOF, "", line, column));
        }

        return tokens;
    }

    /**
     * Get the next token from the input
     */
    private Token nextToken() {
        // Skip whitespace (except newlines)
        while (position < source.length() && Character.isWhitespace(source.charAt(position)) && source.charAt(position) != '\n') {
            advance();
        }

        if (position >= source.length()) {
            return new Token(TokenType.EOF, "", line, column);
        }

        char current = source.charAt(position);

        // Newline
        if (current == '\n') {
            int startColumn = column;
            advance();
            return new Token(TokenType.NEWLINE, "\\n", line - 1, startColumn);
        }

        // Comments - must come before checking for /
        if (current == '/' && position + 1 < source.length() && source.charAt(position + 1) == '/') {
            return scanComment();
        }

        // String literals
        if (current == '"') {
            return scanString();
        }

        // Numbers
        if (Character.isDigit(current)) {
            return scanNumber();
        }

        // Identifiers and keywords
        if (Character.isLetter(current) || current == '_') {
            return scanIdentifier();
        }

        // Operators and punctuation
        return scanOperator();
    }

    /**
     * Scan a string literal
     */
    private Token scanString() {
        int startLine = line;
        int startColumn = column;
        StringBuilder value = new StringBuilder();

        advance(); // Skip opening quote

        while (position < source.length() && source.charAt(position) != '"') {
            if (source.charAt(position) == '\\' && position + 1 < source.length()) {
                advance(); // Skip backslash
                switch (source.charAt(position)) {
                    case 'n': value.append('\n'); break;
                    case 't': value.append('\t'); break;
                    case '"': value.append('"'); break;
                    case '\\': value.append('\\'); break;
                    default: value.append(source.charAt(position));
                }
            } else {
                value.append(source.charAt(position));
            }
            advance();
        }

        if (position >= source.length()) {
            // Error: unterminated string
            return new Token(TokenType.UNKNOWN, value.toString(), startLine, startColumn);
        }

        advance(); // Skip closing quote
        return new Token(TokenType.STRING_LITERAL, value.toString(), startLine, startColumn);
    }

    /**
     * Scan a number
     */
    private Token scanNumber() {
        int startLine = line;
        int startColumn = column;
        StringBuilder value = new StringBuilder();

        while (position < source.length() && Character.isDigit(source.charAt(position))) {
            value.append(source.charAt(position));
            advance();
        }

        // Handle decimal numbers
        if (position < source.length() && source.charAt(position) == '.' &&
                position + 1 < source.length() && Character.isDigit(source.charAt(position + 1))) {
            value.append('.');
            advance();

            while (position < source.length() && Character.isDigit(source.charAt(position))) {
                value.append(source.charAt(position));
                advance();
            }
        }

        return new Token(TokenType.NUMBER, value.toString(), startLine, startColumn);
    }

    /**
     * Scan an identifier or keyword
     */
    private Token scanIdentifier() {
        int startLine = line;
        int startColumn = column;
        StringBuilder value = new StringBuilder();

        while (position < source.length() &&
                (Character.isLetterOrDigit(source.charAt(position)) || source.charAt(position) == '_')) {
            value.append(source.charAt(position));
            advance();
        }

        String identifier = value.toString();
        TokenType type = KEYWORDS.getOrDefault(identifier, TokenType.IDENTIFIER);

        return new Token(type, identifier, startLine, startColumn);
    }

    /**
     * Scan a comment
     */
    private Token scanComment() {
        int startLine = line;
        int startColumn = column;
        StringBuilder value = new StringBuilder();

        // Skip the initial //
        advance();
        advance();

        // Read until end of line
        while (position < source.length() && source.charAt(position) != '\n') {
            value.append(source.charAt(position));
            advance();
        }

        // Comments are usually ignored, but we'll include them for completeness
        Token comment = new Token(TokenType.COMMENT, value.toString(), startLine, startColumn);

        // Skip the comment token in tokenize() method
        return null;
    }

    /**
     * Scan operators and punctuation
     */
    private Token scanOperator() {
        int startLine = line;
        int startColumn = column;
        char current = source.charAt(position);

        switch (current) {
            case '=':
                if (peek() == '=') {
                    advance();
                    advance();
                    return new Token(TokenType.DOUBLE_EQUALS, "==", startLine, startColumn);
                }
                advance();
                return new Token(TokenType.EQUALS, "=", startLine, startColumn);

            case '!':
                if (peek() == '=') {
                    advance();
                    advance();
                    return new Token(TokenType.NOT_EQUALS, "!=", startLine, startColumn);
                }
                break;

            case '<':
                if (peek() == '=') {
                    advance();
                    advance();
                    return new Token(TokenType.LESS_EQUALS, "<=", startLine, startColumn);
                }
                advance();
                return new Token(TokenType.LESS_THAN, "<", startLine, startColumn);

            case '>':
                if (peek() == '=') {
                    advance();
                    advance();
                    return new Token(TokenType.GREATER_EQUALS, ">=", startLine, startColumn);
                }
                advance();
                return new Token(TokenType.GREATER_THAN, ">", startLine, startColumn);

            case '&':
                if (peek() == '&') {
                    advance();
                    advance();
                    return new Token(TokenType.AND, "&&", startLine, startColumn);
                }
                break;

            case '|':
                if (peek() == '|') {
                    advance();
                    advance();
                    return new Token(TokenType.OR, "||", startLine, startColumn);
                }
                break;

            case '{':
                advance();
                return new Token(TokenType.LEFT_BRACE, "{", startLine, startColumn);

            case '}':
                advance();
                return new Token(TokenType.RIGHT_BRACE, "}", startLine, startColumn);

            case '(':
                advance();
                return new Token(TokenType.LEFT_PAREN, "(", startLine, startColumn);

            case ')':
                advance();
                return new Token(TokenType.RIGHT_PAREN, ")", startLine, startColumn);

            case ',':
                advance();
                return new Token(TokenType.COMMA, ",", startLine, startColumn);

            case '.':
                advance();
                return new Token(TokenType.DOT, ".", startLine, startColumn);

            case '$':
                advance();
                return new Token(TokenType.DOLLAR, "$", startLine, startColumn);
        }

        // Unknown character
        advance();
        return new Token(TokenType.UNKNOWN, String.valueOf(current), startLine, startColumn);
    }

    /**
     * Peek at the next character without advancing
     */
    private char peek() {
        if (position + 1 >= source.length()) {
            return '\0';
        }
        return source.charAt(position + 1);
    }

    /**
     * Advance to the next character
     */
    private void advance() {
        if (position < source.length()) {
            if (source.charAt(position) == '\n') {
                line++;
                column = 1;
            } else {
                column++;
            }
            position++;
        }
    }
}