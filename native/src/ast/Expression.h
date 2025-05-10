#pragma once

#include <ASTNode.h>
#include <string>

class Expression : public ASTNode {
    public:
        virtual std::string toJson() const = 0;
    };
    