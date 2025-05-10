#pragma once
#include <string>
#include <vector>
#include "Token.h"

class Lexer {
private:
    std::string source;
    size_t position = 0;
    size_t line = 1;
    size_t column = 1;
    
    char peek() const;
    char advance();
    bool isAtEnd() const;
    void skipWhitespace();
    Token scanToken();
    Token scanIdentifier();
    Token scanString();
    Token scanNumber();
    Token scanComment();
    
public:
    Lexer(const std::string& source);
    std::vector<Token> tokenize();
};