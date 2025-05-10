#pragma once
#include <string>
#include <vector>
#include <memory>
#include <unordered_map>
#include <Expression.h>

class TypeLiteral : public Expression {
    private:
        std::string typeName;
        
    public:
        TypeLiteral(const std::string& typeName) : typeName(typeName) {}
        
        const std::string& getTypeName() const { return typeName; }
        
        std::string toJson() const override {
            return "{\"type\":\"TypeLiteral\",\"typeName\":\"" + typeName + "\"}";
        }
    };
    