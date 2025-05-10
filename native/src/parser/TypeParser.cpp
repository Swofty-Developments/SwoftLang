// TypeParser.cpp
#include "TypeParser.h"
#include <stdexcept>

TypeParser::TypeParser(const std::vector<Token>& tokens) : tokens(tokens) {}

Token TypeParser::peek() const {
    if (isAtEnd()) return tokens.back(); // Return EOF token
    return tokens[current];
}

Token TypeParser::advance() {
    if (!isAtEnd()) current++;
    return tokens[current - 1];
}

bool TypeParser::isAtEnd() const {
    return current >= tokens.size() || tokens[current].type == TokenType::END_OF_FILE;
}

bool TypeParser::match(TokenType type) {
    if (check(type)) {
        advance();
        return true;
    }
    return false;
}

bool TypeParser::check(TokenType type) const {
    if (isAtEnd()) return false;
    return peek().type == type;
}

std::shared_ptr<DataType> TypeParser::parseType() {
    Token token = peek();
    
    // Handle 'either' keyword specially
    if (match(TokenType::EITHER)) {
        return parseEitherType();
    }
    
    // Handle regular identifiers
    if (match(TokenType::IDENTIFIER)) {
        Token typeName = tokens[current - 1];
        
        // Accept any identifier as a type (including "Player", "Location", etc.)
        return DataType::fromString(typeName.value);
    }
    
    throw std::runtime_error("Expected type name, found token type " + 
                            std::to_string((int)token.type) + " value '" + token.value + "'");
}

std::shared_ptr<DataType> TypeParser::parseEitherType() {
    // Already matching EITHER token, now expect '<'
    if (!match(TokenType::LEFT_ANGLE)) {
        throw std::runtime_error("Expected '<' after 'either'");
    }
    
    auto eitherType = std::make_shared<DataType>(BaseType::EITHER);
    
    // Parse first subtype
    eitherType->addSubType(parseType());
    
    // Parse additional subtypes
    while (match(TokenType::PIPE)) {
        eitherType->addSubType(parseType());
    }
    
    if (!match(TokenType::RIGHT_ANGLE)) {
        throw std::runtime_error("Expected '>' to close 'either<>' type");
    }
    
    return eitherType;
}

std::shared_ptr<DataType> TypeParser::parse() {
    return parseType();
}