#pragma once
#include <vector>
#include <memory>
#include "Token.h"
#include "Command.h"
#include "Variable.h"

class CommandParser {
private:
    std::vector<Token> tokens;
    size_t current = 0;
    
    Token peek() const;
    Token advance();
    bool match(TokenType type);
    bool check(TokenType type) const;
    
    void parseCommandProperties(std::shared_ptr<Command> command);
    void parseArgumentsBlock(std::shared_ptr<Command> command);
    void parseExecuteBlock(std::shared_ptr<Command> command);
    std::string parseBlockContent();
    
public:
    CommandParser(const std::vector<Token>& tokens);
    std::vector<std::shared_ptr<Command>> parse();
    bool isAtEnd() const;
    void skipWhitespace();
    std::shared_ptr<Command> parseCommand();
};