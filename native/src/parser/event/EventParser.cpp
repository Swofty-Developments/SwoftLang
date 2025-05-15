#include "EventParser.h"
#include "ExecuteBlockParser.h"
#include <stdexcept>

EventParser::EventParser(const std::vector<Token>& tokens) : tokens(tokens) {}

Token EventParser::peek() const {
    if (isAtEnd()) return tokens.back();
    return tokens[current];
}

Token EventParser::advance() {
    if (!isAtEnd()) current++;
    return tokens[current - 1];
}

bool EventParser::isAtEnd() const {
    return current >= tokens.size() || tokens[current].type == TokenType::END_OF_FILE;
}

bool EventParser::match(TokenType type) {
    if (check(type)) {
        advance();
        return true;
    }
    return false;
}

bool EventParser::check(TokenType type) const {
    if (isAtEnd()) return false;
    return peek().type == type;
}

void EventParser::skipWhitespace() {
    while (!isAtEnd() && peek().type == TokenType::WHITESPACE) {
        advance();
    }
}

std::shared_ptr<Event> EventParser::parseEvent() {
    if (!match(TokenType::EVENT)) {
        throw std::runtime_error("Expected 'event' keyword");
    }
    
    if (!match(TokenType::IDENTIFIER)) {
        throw std::runtime_error("Expected event name");
    }
    
    std::string eventName = tokens[current - 1].value;
    auto event = std::make_shared<Event>(eventName);
    
    if (!match(TokenType::LEFT_BRACE)) {
        throw std::runtime_error("Expected '{' after event name");
    }
    
    parseEventProperties(event);
    
    if (!match(TokenType::RIGHT_BRACE)) {
        throw std::runtime_error("Expected '}' to close event definition");
    }
    
    return event;
}

void EventParser::parseEventProperties(std::shared_ptr<Event> event) {
    while (!isAtEnd() && !check(TokenType::RIGHT_BRACE)) {
        skipWhitespace();
        
        if (match(TokenType::IDENTIFIER)) {
            std::string propertyName = tokens[current - 1].value;
            
            if (propertyName == "priority") {
                if (!match(TokenType::COLON)) {
                    throw std::runtime_error("Expected ':' after 'priority'");
                }
                
                if (!match(TokenType::NUMBER)) {
                    throw std::runtime_error("Expected priority value as number");
                }
                
                int priority = std::stoi(tokens[current - 1].value);
                event->setPriority(priority);
            }
            else if (propertyName == "execute") {
                // Parse execute block
                if (!match(TokenType::LEFT_BRACE)) {
                    throw std::runtime_error("Expected '{' after 'execute'");
                }
                
                // Extract all tokens in the execute block
                std::vector<Token> blockTokens;
                int braceCount = 1;
                
                while (!isAtEnd() && braceCount > 0) {
                    Token token = peek();
                    
                    if (token.type == TokenType::LEFT_BRACE) {
                        braceCount++;
                    } else if (token.type == TokenType::RIGHT_BRACE) {
                        braceCount--;
                        if (braceCount == 0) {
                            break;
                        }
                    }
                    
                    blockTokens.push_back(token);
                    advance();
                }
                
                // Consume the closing brace
                if (!isAtEnd() && peek().type == TokenType::RIGHT_BRACE) {
                    advance();
                }
                
                // Create an execute block parser and parse the statements
                ExecuteBlockParser executeParser(blockTokens);
                auto executeBlock = executeParser.parseExecuteBlock();
                
                event->setExecuteBlock(executeBlock);
            }
            else {
                throw std::runtime_error("Unknown event property: " + propertyName);
            }
        } else {
            advance(); // Skip unexpected token
        }
    }
}