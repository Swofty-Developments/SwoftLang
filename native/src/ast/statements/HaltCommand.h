#pragma once
#include <string>
#include <vector>
#include <memory>
#include <unordered_map>
#include <Statement.h>
#include <Expression.h>

class HaltCommand : public Statement {
    public:
        std::string toJson() const override {
            return "{\"type\":\"HaltCommand\"}";
        }
    };