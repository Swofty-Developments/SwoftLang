#pragma once
#include <vector>
#include <memory>
#include <string>
#include "ASTNode.h"
#include "Statement.h"

class ExecuteBlock : public ASTNode {
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
        std::string json = "{\"type\":\"ExecuteBlock\",\"statements\":[";
        for (size_t i = 0; i < statements.size(); i++) {
            if (i > 0) json += ",";
            json += statements[i]->toJson();
        }
        json += "]}";
        return json;
    }
};