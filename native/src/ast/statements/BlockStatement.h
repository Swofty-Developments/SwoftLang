#pragma once
#include <string>
#include <vector>
#include <memory>
#include <unordered_map>
#include <Statement.h>
#include <Expression.h>

class BlockStatement : public Statement {
    private:
        std::vector<std::shared_ptr<Statement>> statements;
        
    public:
        void addStatement(std::shared_ptr<Statement> statement) {
            statements.push_back(statement);
        }
        
        const std::vector<std::shared_ptr<Statement>>& getStatements() const {
            return statements;
        }
        
        std::string toJson() const override {
            std::string json = "{\"type\":\"BlockStatement\",\"statements\":[";
            for (size_t i = 0; i < statements.size(); i++) {
                if (i > 0) json += ",";
                json += statements[i]->toJson();
            }
            json += "]}";
            return json;
        }
    };