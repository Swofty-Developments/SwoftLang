#pragma once
#include <string>
#include <vector>
#include <memory>
#include <unordered_map>
#include <Statement.h>
#include <Expression.h>

class VariableAssignment : public Statement {
    private:
        std::string variableName;
        std::shared_ptr<Expression> value;
        
    public:
        VariableAssignment(const std::string& variableName, std::shared_ptr<Expression> value)
            : variableName(variableName), value(value) {}
        
        const std::string& getVariableName() const { return variableName; }
        std::shared_ptr<Expression> getValue() const { return value; }
        
        std::string toJson() const override {
            return "{\"type\":\"VariableAssignment\",\"variableName\":\"" + variableName + 
                   "\",\"value\":" + value->toJson() + "}";
        }
    };