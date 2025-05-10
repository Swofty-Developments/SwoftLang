// VariableParser.cpp
#include "VariableParser.h"
#include "TypeParser.h"
#include <stdexcept>
#include <iostream>

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
    if (peek().type != type) {
        std::cout << "check() - Expected type " << (int)type 
                  << ", but found type " << (int)peek().type 
                  << " value '" << peek().value << "'" << std::endl;
    }
    return peek().type == type;
}

std::shared_ptr<Variable> VariableParser::parseVariable() {
    // Skip any leading whitespace
    while (!isAtEnd() && check(TokenType::WHITESPACE)) {
        advance();
    }
    
    if (!match(TokenType::IDENTIFIER)) {
        throw std::runtime_error("Expected variable name");
    }
    
    std::string varName = tokens[current - 1].value;
    
    if (!match(TokenType::COLON)) {
        throw std::runtime_error("Expected ':' after variable name '" + varName + "'");
    }
    
    // Skip whitespace after colon
    while (!isAtEnd() && check(TokenType::WHITESPACE)) {
        advance();
    }
    
    // Check if we have a type - can be an identifier OR the 'either' keyword
    if (isAtEnd() || !(check(TokenType::IDENTIFIER) || check(TokenType::EITHER))) {
        throw std::runtime_error("Expected type name after ':' for variable '" + varName + "'");
    }
    
    // Parse the type
    size_t typeStart = current;
    size_t typeEnd = current;
    
    // Find the end of the type declaration
    // We need to handle 'either' specially since it has an entire syntax
    if (check(TokenType::EITHER)) {
        // For 'either', we need to find the matching '>'
        int angleCount = 0;
        while (typeEnd < tokens.size() && 
               tokens[typeEnd].type != TokenType::END_OF_FILE &&
               tokens[typeEnd].type != TokenType::EQUALS &&
               tokens[typeEnd].type != TokenType::RIGHT_BRACE) {
            
            if (tokens[typeEnd].type == TokenType::LEFT_ANGLE) {
                angleCount++;
            } else if (tokens[typeEnd].type == TokenType::RIGHT_ANGLE) {
                angleCount--;
                if (angleCount <= 0) {
                    typeEnd++; // Include the closing '>'
                    break;
                }
            }
            typeEnd++;
        }
    } else {
        // For regular types, just find the next equals or right brace
        while (typeEnd < tokens.size() && 
               tokens[typeEnd].type != TokenType::END_OF_FILE &&
               tokens[typeEnd].type != TokenType::EQUALS &&
               tokens[typeEnd].type != TokenType::RIGHT_BRACE) {
            typeEnd++;
        }
    }
    
    if (typeEnd == typeStart) {
        throw std::runtime_error("No type found for variable '" + varName + "'");
    }
    
    // Extract tokens for the type
    std::vector<Token> typeTokens(tokens.begin() + typeStart, tokens.begin() + typeEnd);
    typeTokens.push_back(Token(TokenType::END_OF_FILE, "", 0, 0));
    
    // Debug: Print the tokens we're sending to TypeParser
    std::cout << "Type tokens for variable '" << varName << "':" << std::endl;
    for (const auto& token : typeTokens) {
        std::cout << "  Type: " << (int)token.type << " Value: '" << token.value << "'" << std::endl;
    }
    
    // Parse the type using TypeParser
    TypeParser typeParser(typeTokens);
    std::shared_ptr<DataType> type;
    
    try {
        type = typeParser.parse();
    } catch (const std::exception& e) {
        // If type parsing fails, provide more context
        std::string typeStr;
        for (size_t i = typeStart; i < typeEnd; i++) {
            typeStr += tokens[i].value + " ";
        }
        throw std::runtime_error("Failed to parse type '" + typeStr + "' for variable '" + varName + "': " + e.what());
    }
    
    // Update current position
    current = typeEnd;
    
    // Create the variable
    auto variable = std::make_shared<Variable>(varName, type);
    
    // Skip whitespace before checking for default value
    while (!isAtEnd() && check(TokenType::WHITESPACE)) {
        advance();
    }
    
    // Check for default value
    if (match(TokenType::EQUALS)) {
        // Skip whitespace after equals
        while (!isAtEnd() && check(TokenType::WHITESPACE)) {
            advance();
        }
        
        if (match(TokenType::IDENTIFIER) || match(TokenType::STRING_LITERAL) || match(TokenType::NUMBER)) {
            variable->setDefault(tokens[current - 1].value);
        } else {
            throw std::runtime_error("Expected default value after '=' for variable '" + varName + "'");
        }
    }
    
    return variable;
}

std::shared_ptr<Variable> VariableParser::parse() {
    return parseVariable();
}