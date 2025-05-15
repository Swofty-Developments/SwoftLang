#pragma once
#include "Statement.h"

class CancelEventStatement : public Statement {
public:
    CancelEventStatement() = default;
    
    virtual std::string toJson() const override {
        return "{ \"type\": \"CancelEventStatement\" }";
    }
};