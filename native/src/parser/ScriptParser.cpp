// ScriptParser.cpp
#include "ScriptParser.h"
#include "CommandParser.h"
#include "EventParser.h"
#include <stdexcept>
#include <iostream>

ScriptParser::ScriptParser(const std::vector<Token>& tokens) : tokens(tokens) {}

Token ScriptParser::peek() const {
    if (isAtEnd()) return tokens.back();
    return tokens[current];
}

Token ScriptParser::advance() {
    if (!isAtEnd()) current++;
    return tokens[current - 1];
}

bool ScriptParser::isAtEnd() const {
    return current >= tokens.size() || tokens[current].type == TokenType::END_OF_FILE;
}

bool ScriptParser::match(TokenType type) {
    if (check(type)) {
        advance();
        return true;
    }
    return false;
}

bool ScriptParser::check(TokenType type) const {
    if (isAtEnd()) return false;
    return peek().type == type;
}

void ScriptParser::skipWhitespace() {
    while (!isAtEnd() && peek().type == TokenType::WHITESPACE) {
        advance();
    }
}

void ScriptParser::parseAll() {
    commands.clear();
    events.clear();
    
    while (!isAtEnd()) {
        skipWhitespace();
        
        if (isAtEnd()) {
            break;
        }
        
        Token current = peek();
        
        // Check if it's a command
        if (current.type == TokenType::COMMAND) {
            try {
                // Parse command(s) with aliases
                auto parsedCommands = parseCommandsWithAliases();
                commands.insert(commands.end(), parsedCommands.begin(), parsedCommands.end());
            } catch (const std::exception& e) {
                std::cerr << "Error parsing command: " << e.what() << std::endl;
                skipToNextDefinition();
            }
        }
        // Check if it's an event
        else if (current.type == TokenType::EVENT) {
            try {
                // Parse event
                auto parsedEvent = parseEvent();
                if (parsedEvent) {
                    events.push_back(parsedEvent);
                }
            } catch (const std::exception& e) {
                std::cerr << "Error parsing event: " << e.what() << std::endl;
                skipToNextDefinition();
            }
        }
        // Skip unknown tokens
        else {
            advance();
        }
    }
}

std::vector<std::shared_ptr<Command>> ScriptParser::parseCommands() {
    parseAll();
    return commands;
}

std::vector<std::shared_ptr<Event>> ScriptParser::parseEvents() {
    parseAll();
    return events;
}

// Helper method to parse commands (with aliases support)
std::vector<std::shared_ptr<Command>> ScriptParser::parseCommandsWithAliases() {
    // Extract tokens for this command definition
    size_t start = current;
    std::vector<std::string> commandNames;
    
    // Parse all command declarations before the opening brace
    while (!isAtEnd()) {
        if (!match(TokenType::COMMAND)) {
            if (commandNames.empty()) {
                throw std::runtime_error("Expected 'command' keyword");
            } else {
                break; // We've finished parsing command names
            }
        }
        
        skipWhitespace();
        
        if (!match(TokenType::STRING_LITERAL)) {
            throw std::runtime_error("Expected command name as string literal");
        }
        
        commandNames.push_back(tokens[current - 1].value);
        
        skipWhitespace();
        
        // Check if there's a comma for more aliases
        if (check(TokenType::COMMA)) {
            advance(); // consume comma
            skipWhitespace();
        } else {
            break;
        }
    }
    
    // Parse command body
    int braceCount = 0;
    std::vector<Token> commandTokens;
    
    // Include the command names we just parsed
    for (size_t i = start; i < current; i++) {
        commandTokens.push_back(tokens[i]);
    }
    
    // Parse until we find the matching closing brace
    if (!check(TokenType::LEFT_BRACE)) {
        throw std::runtime_error("Expected '{' after command name(s)");
    }
    
    while (!isAtEnd()) {
        Token token = peek();
        commandTokens.push_back(token);
        
        if (token.type == TokenType::LEFT_BRACE) {
            braceCount++;
        } else if (token.type == TokenType::RIGHT_BRACE) {
            braceCount--;
            if (braceCount == 0) {
                advance(); // consume the closing brace
                break;
            }
        }
        advance();
    }
    
    // Add EOF token
    commandTokens.push_back(Token(TokenType::END_OF_FILE, "", 0, 0));
    
    // Parse using CommandParser
    CommandParser commandParser(commandTokens);
    return commandParser.parseCommandsWithAliases();
}

// Helper method to parse an event
std::shared_ptr<Event> ScriptParser::parseEvent() {
    // Extract tokens for this event definition
    std::vector<Token> eventTokens;
    int braceCount = 0;
    
    // Parse until we find the matching closing brace
    while (!isAtEnd()) {
        Token token = peek();
        eventTokens.push_back(token);
        
        if (token.type == TokenType::LEFT_BRACE) {
            braceCount++;
        } else if (token.type == TokenType::RIGHT_BRACE) {
            braceCount--;
            if (braceCount == 0) {
                advance(); // consume the closing brace
                break;
            }
        }
        advance();
    }
    
    // Add EOF token
    eventTokens.push_back(Token(TokenType::END_OF_FILE, "", 0, 0));
    
    // Parse using EventParser
    EventParser eventParser(eventTokens);
    return eventParser.parseEvent();
}

// Helper method to skip to the next command or event definition
void ScriptParser::skipToNextDefinition() {
    while (!isAtEnd()) {
        Token token = peek();
        
        // Look for next command or event keyword
        if (token.type == TokenType::COMMAND || 
            (token.value == "event" && token.type == TokenType::IDENTIFIER)) {
            break;
        }
        
        advance();
    }
}