#pragma once
#include <vector>
#include <memory>
#include "Token.h"
#include "Event.h"

class EventParser {
public:
    EventParser(const std::vector<Token>& tokens);
    std::shared_ptr<Event> parseEvent();
    bool isAtEnd() const;
    
private:
    std::vector<Token> tokens;
    size_t current = 0;
    
    Token peek() const;
    Token advance();
    bool match(TokenType type);
    bool check(TokenType type) const;
    void skipWhitespace();
    
    void parseEventProperties(std::shared_ptr<Event> event);
};