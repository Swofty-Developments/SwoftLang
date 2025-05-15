#pragma once
#include "Expression.h"
#include <string>

class EventAccessExpression : public Expression {
private:
    std::string property;

public:
    EventAccessExpression(const std::string& property) : property(property) {}
    
    const std::string& getProperty() const { return property; }
};