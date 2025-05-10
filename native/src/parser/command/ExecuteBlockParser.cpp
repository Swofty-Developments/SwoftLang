#include "ExecuteBlockParser.h"
#include <stdexcept>
#include <HaltCommand.h>
#include <iostream>
#include <IfStatement.h>
#include <SendCommand.h>
#include <VariableAssignment.h>
#include <TypeLiteral.h>
#include <StringLiteral.h>
#include <VariableReference.h>
#include <BlockStatement.h>
#include <TeleportCommand.h>

ExecuteBlockParser::ExecuteBlockParser(const std::vector<Token>& tokens) : tokens(tokens) {}

Token ExecuteBlockParser::peek() const {
    if (isAtEnd()) {
        if (!tokens.empty()) {
            return tokens.back();
        }
        // Return an EOF token if tokens is empty
        return Token(TokenType::END_OF_FILE, "", 0, 0);
    }
    return tokens[current];
}

Token ExecuteBlockParser::advance() {
    if (!isAtEnd()) current++;
    return tokens[current - 1];
}

bool ExecuteBlockParser::isAtEnd() const {
    return current >= tokens.size() || tokens[current].type == TokenType::END_OF_FILE;
}

bool ExecuteBlockParser::match(TokenType type) {
    if (check(type)) {
        advance();
        return true;
    }
    return false;
}

bool ExecuteBlockParser::check(TokenType type) const {
    if (isAtEnd()) return false;
    return peek().type == type;
}

Token ExecuteBlockParser::consume(TokenType expected, const std::string& message) {
    if (check(expected)) return advance();
    throw std::runtime_error(message + " at line " + std::to_string(peek().line) + 
                           ", column " + std::to_string(peek().column));
}

void ExecuteBlockParser::skipWhitespace() {
    while (match(TokenType::WHITESPACE) || match(TokenType::COMMENT)) {
        // Skip whitespace and comments
    }
}

std::shared_ptr<ExecuteBlock> ExecuteBlockParser::parseExecuteBlock() {
    auto block = std::make_shared<ExecuteBlock>();
    
    skipWhitespace();
    
    while (!isAtEnd() && !check(TokenType::RIGHT_BRACE)) {
        skipWhitespace();
        
        if (isAtEnd() || check(TokenType::RIGHT_BRACE)) {
            break;
        }
        
        auto statement = parseStatement();
        if (statement) {
            block->addStatement(statement);
        }
    }
    
    return block;
}

std::shared_ptr<Statement> ExecuteBlockParser::parseStatement() {
    skipWhitespace();
    
    if (match(TokenType::IF)) {
        return parseIfStatement();
    }
    
    if (match(TokenType::SEND)) {
        return parseSendCommand();
    }
    
    if (match(TokenType::TELEPORT)) {
        return parseTeleportCommand();
    }
    
    if (match(TokenType::HALT)) {
        skipWhitespace();
        return std::make_shared<HaltCommand>();
    }
    
    if (match(TokenType::LEFT_BRACE)) {
        return parseBlockStatement();
    }
    
    // Check for variable assignment
    if (check(TokenType::IDENTIFIER)) {
        Token name = peek();
        size_t savedPos = current;
        advance();
        skipWhitespace();
        
        if (match(TokenType::EQUALS)) {
            // Reset and parse as assignment
            current = savedPos;
            return parseVariableAssignment();
        } else {
            // Not an assignment, backtrack
            current = savedPos;
        }
    }
    
    // Skip unexpected tokens
    if (!isAtEnd()) {
        std::cerr << "Unexpected token: " << peek().value << std::endl;
        advance();
    }
    
    return nullptr;
}

std::shared_ptr<Statement> ExecuteBlockParser::parseIfStatement() {
    skipWhitespace();
    
    auto condition = parseExpression();
    
    skipWhitespace();
    consume(TokenType::LEFT_BRACE, "Expected '{' after if condition");
    
    auto thenStatement = parseBlockStatement();
    
    std::shared_ptr<Statement> elseStatement = nullptr;
    
    skipWhitespace();
    if (match(TokenType::ELSE)) {
        skipWhitespace();
        
        if (match(TokenType::IF)) {
            // else if
            elseStatement = parseIfStatement();
        } else if (match(TokenType::LEFT_BRACE)) {
            // else block
            elseStatement = parseBlockStatement();
        } else {
            throw std::runtime_error("Expected '{' or 'if' after 'else'");
        }
    }
    
    return std::make_shared<IfStatement>(condition, thenStatement, elseStatement);
}

std::shared_ptr<Statement> ExecuteBlockParser::parseSendCommand() {
    skipWhitespace();
    
    auto message = parseExpression();
    
    std::shared_ptr<Expression> target = nullptr;
    
    skipWhitespace();
    if (match(TokenType::TO)) {
        skipWhitespace();
        target = parseExpression();
    }
    
    skipWhitespace();
    
    return std::make_shared<SendCommand>(message, target);
}

std::shared_ptr<Statement> ExecuteBlockParser::parseTeleportCommand() {
    skipWhitespace();
    
    auto entity = parseExpression();
    
    skipWhitespace();
    consume(TokenType::TO, "Expected 'to' in teleport command");
    skipWhitespace();
    
    auto target = parseExpression();
    
    skipWhitespace();
    
    return std::make_shared<TeleportCommand>(entity, target);
}

std::shared_ptr<Statement> ExecuteBlockParser::parseVariableAssignment() {
    Token name = consume(TokenType::IDENTIFIER, "Expected variable name");
    
    skipWhitespace();
    consume(TokenType::EQUALS, "Expected '=' after variable name");
    skipWhitespace();
    
    auto value = parseExpression();
    
    skipWhitespace();
    
    return std::make_shared<VariableAssignment>(name.value, value);
}

std::shared_ptr<Statement> ExecuteBlockParser::parseBlockStatement() {
    auto block = std::make_shared<BlockStatement>();
    
    while (!isAtEnd() && !check(TokenType::RIGHT_BRACE)) {
        skipWhitespace();
        
        if (isAtEnd() || check(TokenType::RIGHT_BRACE)) {
            break;
        }
        
        auto statement = parseStatement();
        if (statement) {
            block->addStatement(statement);
        }
    }
    
    consume(TokenType::RIGHT_BRACE, "Expected '}' to close block");
    
    return block;
}

std::shared_ptr<Expression> ExecuteBlockParser::parseExpression() {
    return parseLogicalOr();
}

std::shared_ptr<Expression> ExecuteBlockParser::parseLogicalOr() {
    auto expr = parseLogicalAnd();
    
    while (match(TokenType::OR)) {
        skipWhitespace();
        auto right = parseLogicalAnd();
        expr = std::make_shared<BinaryExpression>(expr, BinaryExpression::Operator::OR, right);
    }
    
    return expr;
}

std::shared_ptr<Expression> ExecuteBlockParser::parseLogicalAnd() {
    auto expr = parseComparison();
    
    while (match(TokenType::AND)) {
        skipWhitespace();
        auto right = parseComparison();
        expr = std::make_shared<BinaryExpression>(expr, BinaryExpression::Operator::AND, right);
    }
    
    return expr;
}

std::shared_ptr<Expression> ExecuteBlockParser::parseComparison() {
    auto expr = parseIsExpression();
    
    while (true) {
        BinaryExpression::Operator op;
        
        if (match(TokenType::EQUALS)) {
            op = BinaryExpression::Operator::EQUALS;
        } else if (match(TokenType::NOT_EQUALS)) {
            op = BinaryExpression::Operator::NOT_EQUALS;
        } else if (match(TokenType::LESS_THAN)) {
            op = BinaryExpression::Operator::LESS_THAN;
        } else if (match(TokenType::GREATER_THAN)) {
            op = BinaryExpression::Operator::GREATER_THAN;
        } else if (match(TokenType::LESS_EQUALS)) {
            op = BinaryExpression::Operator::LESS_EQUALS;
        } else if (match(TokenType::GREATER_EQUALS)) {
            op = BinaryExpression::Operator::GREATER_EQUALS;
        } else {
            break;
        }
        
        skipWhitespace();
        auto right = parseIsExpression();
        expr = std::make_shared<BinaryExpression>(expr, op, right);
    }
    
    return expr;
}

std::shared_ptr<Expression> ExecuteBlockParser::parseIsExpression() {
    auto expr = parsePrimary();
    
    skipWhitespace();
    if (match(TokenType::IS)) {
        bool isNot = false;
        
        skipWhitespace();
        if (match(TokenType::NOT)) {
            isNot = true;
            skipWhitespace();
        }
        
        consume(TokenType::IDENTIFIER, "Expected 'a' after 'is' (e.g., 'is a Player')");
        if (tokens[current - 1].value != "a") {
            throw std::runtime_error("Expected 'a' after 'is'");
        }
        
        skipWhitespace();
        Token typeName = consume(TokenType::IDENTIFIER, "Expected type name after 'is a'");
        
        auto typeLiteral = std::make_shared<TypeLiteral>(typeName.value);
        
        auto op = isNot ? BinaryExpression::Operator::IS_NOT_TYPE : BinaryExpression::Operator::IS_TYPE;
        expr = std::make_shared<BinaryExpression>(expr, op, typeLiteral);
    }
    
    return expr;
}

std::shared_ptr<Expression> ExecuteBlockParser::parsePrimary() {
    skipWhitespace();
    
    if (match(TokenType::STRING_LITERAL)) {
        return std::make_shared<StringLiteral>(tokens[current - 1].value);
    }
    
    if (match(TokenType::IDENTIFIER)) {
        std::string identifier = tokens[current - 1].value;
        
        // Check for dot notation (e.g., args.player)
        if (match(TokenType::DOT)) {
            Token property = consume(TokenType::IDENTIFIER, "Expected property name after '.'");
            identifier += "." + property.value;
        }
        
        // Check for string interpolation (e.g., ${variable})
        if (identifier == "$" && match(TokenType::LEFT_BRACE)) {
            Token varName = consume(TokenType::IDENTIFIER, "Expected variable name in interpolation");
            std::string fullName = varName.value;
            
            // Support dot notation in interpolation
            while (match(TokenType::DOT)) {
                Token property = consume(TokenType::IDENTIFIER, "Expected property name after '.'");
                fullName += "." + property.value;
            }
            
            consume(TokenType::RIGHT_BRACE, "Expected '}' after variable name");
            return std::make_shared<VariableReference>(fullName);
        }
        
        return std::make_shared<VariableReference>(identifier);
    }
    
    if (match(TokenType::LEFT_PAREN)) {
        auto expr = parseExpression();
        consume(TokenType::RIGHT_PAREN, "Expected ')' after expression");
        return expr;
    }
    
    throw std::runtime_error("Expected expression at line " + std::to_string(peek().line) + 
                           ", column " + std::to_string(peek().column));
}