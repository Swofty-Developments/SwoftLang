// VariableParser.cpp
#include "VariableParser.h"
#include "TypeParser.h"
#include <stdexcept>

VariableParser::VariableParser(const std::vector<Token>& tokens) : tokens(tokens) {}

Token VariableParser::peek() const {
    if (isAtEnd()) return tokens.back(); // Return EOF token
    return tokens[current];
}

Token VariableParser::advance() {
    if (!isAtEnd()) current++;
    return tokens[current - 1];
}

bool VariableParser::isAtEnd() const {
    return current >= tokens.size() || tokens[current].type == TokenType::END_OF_FILE;
}

bool VariableParser::match(TokenType type) {
    if (check(type)) {
        advance();
        return true;
    }
    return false;
}

bool VariableParser::check(TokenType type) const {
    if (isAtEnd()) return false;
    return peek().type == type;
}

std::shared_ptr<Variable> VariableParser::parseVariable() {
    if (!match(TokenType::IDENTIFIER)) {
        throw std::runtime_error("Expected variable name");
    }
    
    std::string varName = tokens[current - 1].value;
    
    if (!match(TokenType::COLON)) {
        throw std::runtime_error("Expected ':' after variable name");
    }
    
    // Parse the type
    size_t typeStart = current;
    size_t typeEnd = current;
    
    // Find the end of the type declaration
    while (typeEnd < tokens.size() && 
           tokens[typeEnd].type != TokenType::END_OF_FILE &&
           tokens[typeEnd].type != TokenType::EQUALS) {
        typeEnd++;
    }
    
    // Extract tokens for the type
    std::vector<Token> typeTokens(tokens.begin() + typeStart, tokens.begin() + typeEnd);
    typeTokens.push_back(Token(TokenType::END_OF_FILE, "", 0, 0));
    
    // Parse the type using TypeParser
    TypeParser typeParser(typeTokens);
    auto type = typeParser.parse();
    
    // Update current position
    current = typeEnd;
    
    // Create the variable
    auto variable = std::make_shared<Variable>(varName, type);
    
    // Check for default value
    if (match(TokenType::EQUALS)) {
        if (match(TokenType::IDENTIFIER) || match(TokenType::STRING_LITERAL) || match(TokenType::NUMBER)) {
            variable->setDefault(tokens[current - 1].value);
        } else {
            throw std::runtime_error("Expected default value after '='");
        }
    }
    
    return variable;
}

std::shared_ptr<Variable> VariableParser::parse() {
    return parseVariable();
}