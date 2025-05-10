#pragma once
#include <string>  // Add missing include

// Base class for all AST nodes
class ASTNode {
public:
    virtual ~ASTNode() = default;
    virtual std::string toJson() const = 0; 
};