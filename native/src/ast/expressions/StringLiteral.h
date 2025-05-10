#pragma once
#include <string>
#include <vector>
#include <memory>
#include <unordered_map>
#include <Expression.h>

class StringLiteral : public Expression {
    private:
        std::string value;
        
    public:
        StringLiteral(const std::string& value) : value(value) {}
        
        const std::string& getValue() const { return value; }
        
        std::string toJson() const override {
            return "{\"type\":\"StringLiteral\",\"value\":\"" + value + "\"}";
        }
    };