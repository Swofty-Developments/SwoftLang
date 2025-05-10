// TypeParser.h
#pragma once
#include <vector>
#include <memory>
#include "Token.h"
#include "DataType.h"

class TypeParser {
private:
    std::vector<Token> tokens;
    size_t current = 0;
    
    Token peek() const;
    Token advance();
    bool isAtEnd() const;
    bool match(TokenType type);
    bool check(TokenType type) const;
    
    std::shared_ptr<DataType> parseType();
    std::shared_ptr<DataType> parseEitherType();

public:
    TypeParser(const std::vector<Token>& tokens);
    std::shared_ptr<DataType> parse();
};