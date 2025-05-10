// CommandParser.cpp
#include "CommandParser.h"
#include "VariableParser.h"
#include <stdexcept>
#include <sstream>
#include <iostream>
#include <Lexer.h>

CommandParser::CommandParser(const std::vector<Token>& tokens) : tokens(tokens) {}

Token CommandParser::peek() const {
    if (isAtEnd()) return tokens.back(); // Return EOF token
    return tokens[current];
}

Token CommandParser::advance() {
    if (!isAtEnd()) current++;
    return tokens[current - 1];
}

bool CommandParser::isAtEnd() const {
    return current >= tokens.size() || tokens[current].type == TokenType::END_OF_FILE;
}

bool CommandParser::match(TokenType type) {
    if (check(type)) {
        advance();
        return true;
    }
    return false;
}

bool CommandParser::check(TokenType type) const {
    if (isAtEnd()) return false;
    return peek().type == type;
}

std::shared_ptr<Command> CommandParser::parseCommand() {
    if (!match(TokenType::IDENTIFIER) || tokens[current - 1].value != "command") {
        throw std::runtime_error("Expected 'command' keyword");
    }
    
    if (!match(TokenType::STRING_LITERAL)) {
        throw std::runtime_error("Expected command name as string literal");
    }
    
    std::string commandName = tokens[current - 1].value;
    auto command = std::make_shared<Command>(commandName);
    
    if (!match(TokenType::LEFT_BRACE)) {
        throw std::runtime_error("Expected '{' after command name");
    }
    
    parseCommandProperties(command);
    
    if (!match(TokenType::RIGHT_BRACE)) {
        throw std::runtime_error("Expected '}' to close command definition");
    }
    
    return command;
}

void CommandParser::parseCommandProperties(std::shared_ptr<Command> command) {
    while (!isAtEnd() && !check(TokenType::RIGHT_BRACE)) {
        if (match(TokenType::IDENTIFIER)) {
            std::string propertyName = tokens[current - 1].value;
            
            if (propertyName == "permission") {
                if (!match(TokenType::COLON)) {
                    throw std::runtime_error("Expected ':' after 'permission'");
                }
                
                if (!match(TokenType::STRING_LITERAL)) {
                    throw std::runtime_error("Expected permission value as string literal");
                }
                
                command->setPermission(tokens[current - 1].value);
            } 
            else if (propertyName == "description") {
                if (!match(TokenType::COLON)) {
                    throw std::runtime_error("Expected ':' after 'description'");
                }
                
                if (!match(TokenType::STRING_LITERAL)) {
                    throw std::runtime_error("Expected description value as string literal");
                }
                
                command->setDescription(tokens[current - 1].value);
            } 
            else if (propertyName == "arguments") {
                parseArgumentsBlock(command);
            }
            else if (propertyName == "execute") {
                parseExecuteBlock(command);
            }
            else {
                throw std::runtime_error("Unknown command property: " + propertyName);
            }
        } else {
            advance(); // Skip unexpected token
        }
    }
}

void CommandParser::parseArgumentsBlock(std::shared_ptr<Command> command) {
    if (!match(TokenType::LEFT_BRACE)) {
        throw std::runtime_error("Expected '{' after 'arguments'");
    }
    
    std::string blockContent = parseBlockContent();
    command->addBlock("arguments", blockContent);
    
    // Parse individual arguments
    std::istringstream iss(blockContent);
    std::string line;
    
    while (std::getline(iss, line)) {
        // Skip empty lines and comments
        if (line.empty() || line.find("//") == 0) continue;
        
        // Create tokens for the line
        Lexer lexer(line);
        std::vector<Token> lineTokens = lexer.tokenize();
        
        if (!lineTokens.empty() && lineTokens[0].type == TokenType::IDENTIFIER) {
            try {
                VariableParser varParser(lineTokens);
                auto variable = varParser.parse();
                command->addArgument(variable);
            } catch (const std::exception& e) {
                std::cerr << "Error parsing argument: " << e.what() << std::endl;
            }
        }
    }
}

void CommandParser::parseExecuteBlock(std::shared_ptr<Command> command) {
    if (!match(TokenType::LEFT_BRACE)) {
        throw std::runtime_error("Expected '{' after 'execute'");
    }
    
    std::string blockContent = parseBlockContent();
    command->addBlock("execute", blockContent);
}

std::string CommandParser::parseBlockContent() {
    std::string content;
    int braceCount = 1;
    
    // Record the position of the first token after the opening brace
    size_t startIndex = current;
    
    // Find the matching closing brace
    while (!isAtEnd() && braceCount > 0) {
        Token token = peek();
        
        if (token.type == TokenType::LEFT_BRACE) {
            braceCount++;
        } else if (token.type == TokenType::RIGHT_BRACE) {
            braceCount--;
            if (braceCount == 0) {
                break; // Don't advance past the closing brace
            }
        }
        advance();
    }
    
    // Record the position of the closing brace
    size_t endIndex = current;
    
    // Now reconstruct the content with proper spacing
    for (size_t i = startIndex; i < endIndex; i++) {
        Token token = tokens[i];
        
        // Add spacing based on the positions
        if (i > startIndex) {
            Token prevToken = tokens[i - 1];
            
            // Check if we need a newline
            if (token.line > prevToken.line) {
                // Add appropriate number of newlines
                for (int line = prevToken.line; line < token.line; line++) {
                    content += "\n";
                }
                // Add indentation (spaces before the token)
                for (int col = 1; col < token.column; col++) {
                    content += " ";
                }
            } else if (token.line == prevToken.line) {
                // Same line, add spaces between tokens
                int expectedPos = prevToken.column + prevToken.value.length();
                if (prevToken.type == TokenType::STRING_LITERAL) {
                    expectedPos += 2; // Account for quotes
                }
                
                for (int pos = expectedPos; pos < token.column; pos++) {
                    content += " ";
                }
            }
        } else {
            // First token, add initial indentation if needed
            for (int col = 1; col < token.column; col++) {
                content += " ";
            }
        }
        
        // Add the token content
        if (token.type == TokenType::STRING_LITERAL) {
            content += "\"" + token.value + "\"";
        } else {
            content += token.value;
        }
    }
    
    // Consume the closing brace
    if (!isAtEnd() && peek().type == TokenType::RIGHT_BRACE) {
        advance();
    }
    
    return content;
}

std::vector<std::shared_ptr<Command>> CommandParser::parse() {
    std::vector<std::shared_ptr<Command>> commands;
    
    while (!isAtEnd()) {
        try {
            auto command = parseCommand();
            commands.push_back(command);
        } catch (const std::exception& e) {
            std::cerr << "Error parsing command: " << e.what() << std::endl;
            
            // Skip to the next "command" keyword
            while (!isAtEnd()) {
                if (check(TokenType::IDENTIFIER) && peek().value == "command") {
                    break;
                }
                advance();
            }
        }
    }
    
    return commands;
}