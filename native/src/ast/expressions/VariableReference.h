#pragma once
#include <string>
#include <vector>
#include <memory>
#include <unordered_map>
#include <Expression.h>

class VariableReference : public Expression {
    private:
        std::string name;
        
    public:
        VariableReference(const std::string& name) : name(name) {}
        
        const std::string& getName() const { return name; }
        
        std::string toJson() const override {
            return "{\"type\":\"VariableReference\",\"name\":\"" + name + "\"}";
        }
    };