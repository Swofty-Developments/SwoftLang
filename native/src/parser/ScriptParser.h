// ScriptParser.h
#pragma once
#include <vector>
#include <memory>
#include "Token.h"
#include "Command.h"
#include "Event.h"

class ScriptParser {
public:
    ScriptParser(const std::vector<Token>& tokens);
    
    std::vector<std::shared_ptr<Command>> parseCommands();
    std::vector<std::shared_ptr<Event>> parseEvents();
    void parseAll(); // Parse both commands and events
    
    bool isAtEnd() const;
    void skipWhitespace();
    
    // Getters for parsed content
    const std::vector<std::shared_ptr<Command>>& getCommands() const { return commands; }
    const std::vector<std::shared_ptr<Event>>& getEvents() const { return events; }
    
private:
    std::vector<Token> tokens;
    size_t current = 0;
    std::vector<std::shared_ptr<Command>> commands;
    std::vector<std::shared_ptr<Event>> events;
    
    Token peek() const;
    Token advance();
    bool match(TokenType type);
    bool check(TokenType type) const;
    
    // Helper methods for parsing
    std::vector<std::shared_ptr<Command>> parseCommandsWithAliases();
    std::shared_ptr<Event> parseEvent();
    void skipToNextDefinition();
};