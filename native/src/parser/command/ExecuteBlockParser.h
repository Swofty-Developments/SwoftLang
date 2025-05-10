#pragma once
#include <vector>
#include <memory>
#include "Token.h"
#include "SwoftLangAST.h"

class ExecuteBlockParser {
private:
    std::vector<Token> tokens;
    size_t current = 0;
    
    Token peek() const;
    Token advance();
    bool isAtEnd() const;
    bool match(TokenType type);
    bool check(TokenType type) const;
    Token consume(TokenType expected, const std::string& message);
    void skipWhitespace();
    
    // Statement parsing methods
    std::shared_ptr<Statement> parseStatement();
    std::shared_ptr<Statement> parseIfStatement();
    std::shared_ptr<Statement> parseSendCommand();
    std::shared_ptr<Statement> parseTeleportCommand();
    std::shared_ptr<Statement> parseVariableAssignment();
    std::shared_ptr<Statement> parseBlockStatement();
    
    // Expression parsing methods
    std::shared_ptr<Expression> parseExpression();
    std::shared_ptr<Expression> parseLogicalOr();
    std::shared_ptr<Expression> parseLogicalAnd();
    std::shared_ptr<Expression> parseComparison();
    std::shared_ptr<Expression> parseIsExpression();
    std::shared_ptr<Expression> parsePrimary();
    
    // Helper methods
    BinaryExpression::Operator parseComparisonOperator();
    
public:
    ExecuteBlockParser(const std::vector<Token>& tokens);
    std::shared_ptr<ExecuteBlock> parseExecuteBlock();
};