// VariableParser.h
#pragma once
#include <vector>
#include <memory>
#include "Token.h"
#include "Variable.h"

class VariableParser {
private:
    std::vector<Token> tokens;
    size_t current = 0;
    
    Token peek() const;
    Token advance();
    bool isAtEnd() const;
    bool match(TokenType type);
    bool check(TokenType type) const;
    
    std::shared_ptr<Variable> parseVariable();

public:
    VariableParser(const std::vector<Token>& tokens);
    std::shared_ptr<Variable> parse();
};