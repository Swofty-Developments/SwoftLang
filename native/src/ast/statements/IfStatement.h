#pragma once
#include <string>
#include <vector>
#include <memory>
#include <unordered_map>
#include <Statement.h>
#include <Expression.h>

class IfStatement : public Statement {
    private:
        std::shared_ptr<Expression> condition;
        std::shared_ptr<Statement> thenStatement;
        std::shared_ptr<Statement> elseStatement;
        
    public:
        IfStatement(std::shared_ptr<Expression> condition, 
                    std::shared_ptr<Statement> thenStatement,
                    std::shared_ptr<Statement> elseStatement = nullptr)
            : condition(condition), thenStatement(thenStatement), elseStatement(elseStatement) {}
        
        std::shared_ptr<Expression> getCondition() const { return condition; }
        std::shared_ptr<Statement> getThenStatement() const { return thenStatement; }
        std::shared_ptr<Statement> getElseStatement() const { return elseStatement; }
        
        std::string toJson() const override {
            std::string json = "{\"type\":\"IfStatement\",\"condition\":" + condition->toJson() +
                              ",\"thenStatement\":" + thenStatement->toJson();
            if (elseStatement) {
                json += ",\"elseStatement\":" + elseStatement->toJson();
            }
            json += "}";
            return json;
        }
    };