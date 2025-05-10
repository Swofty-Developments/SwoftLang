package net.swofty.parser;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.swofty.ast.nodes.Expression;
import net.swofty.ast.nodes.Program;
import net.swofty.ast.nodes.Statement;
import net.swofty.ast.nodes.expressions.BinaryExpression;
import net.swofty.ast.nodes.expressions.StringLiteral;
import net.swofty.ast.nodes.expressions.TypeLiteral;
import net.swofty.ast.nodes.expressions.VariableReference;
import net.swofty.ast.nodes.statements.BlockStatement;
import net.swofty.ast.nodes.statements.HaltCommand;
import net.swofty.ast.nodes.statements.IfStatement;
import net.swofty.ast.nodes.statements.SendCommand;
import net.swofty.ast.nodes.statements.TeleportCommand;
import net.swofty.ast.nodes.statements.VariableAssignment;
import net.swofty.lexer.Token;
import net.swofty.lexer.TokenType;

/**
 * Parser for SwoftLang script
 */
public class SwoftParser {
    private final List<Token> tokens;
    private int current;

    public SwoftParser(List<Token> tokens) {
        this.tokens = tokens;
        this.current = 0;
    }

    /**
     * Parse the token stream into an AST
     */
    public Program parse() {
        List<Statement> statements = new ArrayList<>();

        // Skip any leading newlines
        skipNewlines();

        while (!isAtEnd()) {
            if (peek().getType() == TokenType.EOF) {
                break;
            }

            // Skip newlines between statements
            skipNewlines();

            if (!isAtEnd() && peek().getType() != TokenType.EOF) {
                Statement statement = parseStatement();
                if (statement != null) {
                    statements.add(statement);
                }
            }
        }

        return new Program(statements);
    }

    /**
     * Parse a statement
     */
    private Statement parseStatement() {
        // Skip any leading newlines within the statement
        skipNewlines();

        if (isAtEnd() || peek().getType() == TokenType.EOF) {
            return null;
        }

        if (match(TokenType.IF)) {
            return parseIfStatement();
        }

        if (match(TokenType.LEFT_BRACE)) {
            return parseBlockStatement();
        }

        if (match(TokenType.HALT)) {
            consumeNewline();
            return new HaltCommand();
        }

        if (match(TokenType.SEND)) {
            return parseSendCommand();
        }

        if (match(TokenType.TELEPORT)) {
            return parseTeleportCommand();
        }

        // Check for variable assignment
        if (peek().getType() == TokenType.IDENTIFIER &&
                peekNext() != null && peekNext().getType() == TokenType.EQUALS) {
            return parseVariableAssignment();
        }

        // Unknown statement, skip to next line
        consumeUntilNewline();
        return null;
    }

    /**
     * Parse an if statement
     */
    private IfStatement parseIfStatement() {
        Expression condition = parseExpression();

        if (!match(TokenType.LEFT_BRACE)) {
            throw new ParseException("Expected '{' after if condition", current());
        }

        Statement thenStatement = parseBlockStatement();
        Statement elseStatement = null;

        skipNewlines();

        if (match(TokenType.ELSE)) {
            if (match(TokenType.LEFT_BRACE)) {
                elseStatement = parseBlockStatement();
            } else if (match(TokenType.IF)) {
                // Handle else if
                elseStatement = parseIfStatement();
            } else {
                throw new ParseException("Expected '{' or 'if' after else", current());
            }
        }

        return new IfStatement(condition, thenStatement, elseStatement);
    }

    /**
     * Parse a block statement
     */
    private BlockStatement parseBlockStatement() {
        List<Statement> statements = new ArrayList<>();

        while (!match(TokenType.RIGHT_BRACE) && !isAtEnd()) {
            skipNewlines();

            if (!isAtEnd() && !check(TokenType.RIGHT_BRACE)) {
                Statement statement = parseStatement();
                if (statement != null) {
                    statements.add(statement);
                }
            }
        }

        return new BlockStatement(statements);
    }

    /**
     * Parse a variable assignment
     */
    private VariableAssignment parseVariableAssignment() {
        Token identifier = consume(TokenType.IDENTIFIER, "Expected variable name");
        consume(TokenType.EQUALS, "Expected '=' after variable name");
        Expression value = parseExpression();
        consumeNewline();

        return new VariableAssignment(identifier.getValue(), value);
    }

    /**
     * Parse a send command
     */
    private SendCommand parseSendCommand() {
        Map<String, Expression> arguments = new HashMap<>();

        // Parse the message
        arguments.put("message", parseExpression());

        // Check for optional "to" clause
        if (match(TokenType.TO)) {
            arguments.put("target", parseExpression());
        }

        consumeNewline();
        return new SendCommand(arguments);
    }

    /**
     * Parse a teleport command
     */
    private TeleportCommand parseTeleportCommand() {
        Map<String, Expression> arguments = new HashMap<>();

        // Parse the entity to teleport
        arguments.put("entity", parseExpression());

        // Expect "to"
        consume(TokenType.TO, "Expected 'to' in teleport command");

        // Parse the target
        arguments.put("target", parseExpression());

        consumeNewline();
        return new TeleportCommand(arguments);
    }

    /**
     * Parse an expression
     */
    private Expression parseExpression() {
        return parseLogicalOr();
    }

    /**
     * Parse logical OR expressions
     */
    private Expression parseLogicalOr() {
        Expression expr = parseLogicalAnd();

        while (match(TokenType.OR)) {
            BinaryExpression.Operator operator = BinaryExpression.Operator.OR;
            Expression right = parseLogicalAnd();
            expr = new BinaryExpression(expr, operator, right);
        }

        return expr;
    }

    /**
     * Parse logical AND expressions
     */
    private Expression parseLogicalAnd() {
        Expression expr = parseComparison();

        while (match(TokenType.AND)) {
            BinaryExpression.Operator operator = BinaryExpression.Operator.AND;
            Expression right = parseComparison();
            expr = new BinaryExpression(expr, operator, right);
        }

        return expr;
    }

    /**
     * Parse comparison expressions
     */
    private Expression parseComparison() {
        Expression expr = parseIS();

        while (matchAny(TokenType.DOUBLE_EQUALS, TokenType.NOT_EQUALS, TokenType.LESS_THAN,
                TokenType.GREATER_THAN, TokenType.LESS_EQUALS, TokenType.GREATER_EQUALS)) {
            Token operatorToken = previous();
            BinaryExpression.Operator operator = BinaryExpression.Operator.fromString(operatorToken.getValue());
            Expression right = parseIS();
            expr = new BinaryExpression(expr, operator, right);
        }

        return expr;
    }

    /**
     * Parse "is" and "is not" type checks
     */
    private Expression parseIS() {
        Expression expr = parsePrimary();

        if (match(TokenType.IS)) {
            boolean isNot = match(TokenType.NOT);
            consume(TokenType.A, "Expected 'a' after 'is'");

            Token typeToken = consume(TokenType.IDENTIFIER, "Expected type name");
            TypeLiteral type = new TypeLiteral(typeToken.getValue());

            BinaryExpression.Operator operator = isNot ?
                    BinaryExpression.Operator.IS_NOT_TYPE : BinaryExpression.Operator.IS_TYPE;

            expr = new BinaryExpression(expr, operator, type);
        }

        return expr;
    }

    /**
     * Parse primary expressions
     */
    private Expression parsePrimary() {
        if (match(TokenType.STRING_LITERAL)) {
            return new StringLiteral(previous().getValue());
        }

        if (match(TokenType.IDENTIFIER)) {
            String identifier = previous().getValue();

            // Check for dot notation (e.g., args.player)
            if (match(TokenType.DOT)) {
                Token property = consume(TokenType.IDENTIFIER, "Expected property name after '.'");
                return new VariableReference(identifier + "." + property.getValue());
            }

            // Check for string interpolation (e.g., ${variable})
            if (identifier.equals("$") && match(TokenType.LEFT_BRACE)) {
                Token varName = consume(TokenType.IDENTIFIER, "Expected variable name in interpolation");
                String fullName = varName.getValue();

                // Support dot notation in interpolation
                while (match(TokenType.DOT)) {
                    Token property = consume(TokenType.IDENTIFIER, "Expected property name after '.'");
                    fullName += "." + property.getValue();
                }

                consume(TokenType.RIGHT_BRACE, "Expected '}' after variable name");
                return new VariableReference(fullName);
            }

            return new VariableReference(identifier);
        }

        if (match(TokenType.LEFT_PAREN)) {
            Expression expr = parseExpression();
            consume(TokenType.RIGHT_PAREN, "Expected ')' after expression");
            return expr;
        }

        throw new ParseException("Expected expression", current());
    }

    // Helper methods

    private boolean match(TokenType type) {
        if (check(type)) {
            advance();
            return true;
        }
        return false;
    }

    private boolean matchAny(TokenType... types) {
        for (TokenType type : types) {
            if (match(type)) {
                return true;
            }
        }
        return false;
    }

    private boolean check(TokenType type) {
        if (isAtEnd()) return false;
        return peek().getType() == type;
    }

    private Token advance() {
        if (!isAtEnd()) current++;
        return previous();
    }

    private int current() {
        return current;
    }

    private boolean isAtEnd() {
        return current >= tokens.size();
    }

    private Token peek() {
        if (isAtEnd()) {
            // Return an EOF token when we're at the end
            return new Token(TokenType.EOF, "", 0, 0);
        }
        return tokens.get(current);
    }

    private Token peekNext() {
        if (current + 1 >= tokens.size()) return null;
        return tokens.get(current + 1);
    }

    private Token previous() {
        if (current <= 0) {
            throw new ParseException("Cannot get previous token, already at beginning", current);
        }
        return tokens.get(current - 1);
    }

    private Token consume(TokenType type, String message) {
        if (check(type)) return advance();

        // Create a more descriptive error message
        Token currentToken = peek();
        String enhancedMessage = String.format(
                "%s\nExpected: %s\nFound: %s\nAt line %d, column %d",
                message,
                type,
                currentToken.getType(),
                currentToken.getLine(),
                currentToken.getColumn()
        );

        throw new ParseException(enhancedMessage, current);
    }

    private void consumeNewline() {
        // Skip optional newlines
        while (match(TokenType.NEWLINE)) {
            // Continue consuming newlines
        }
    }

    private void skipNewlines() {
        while (!isAtEnd() && peek().getType() == TokenType.NEWLINE) {
            advance();
        }
    }

    private void consumeUntilNewline() {
        while (!isAtEnd() && peek().getType() != TokenType.NEWLINE && peek().getType() != TokenType.EOF) {
            advance();
        }
        consumeNewline();
    }

    /**
     * Exception for parse errors
     */
    public static class ParseException extends RuntimeException {
        private final int position;

        public ParseException(String message, int position) {
            super(message);
            this.position = position;
        }

        public int getPosition() {
            return position;
        }
    }
}