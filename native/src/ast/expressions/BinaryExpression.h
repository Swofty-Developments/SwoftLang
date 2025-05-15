#pragma once
#include <string>
#include <vector>
#include <memory>
#include <unordered_map>
#include <Expression.h>

class BinaryExpression : public Expression {
    public:
        enum class Operator {
            EQUALS,         // ==
            NOT_EQUALS,     // !=
            LESS_THAN,      // <
            GREATER_THAN,   // >
            LESS_EQUALS,    // <=
            GREATER_EQUALS, // >=
            AND,            // &&
            OR,             // ||
            IS_TYPE,        // is a
            IS_NOT_TYPE,    // is not a
            CONTAINS,       // For string contains checks
            CONCATENATE     // + for string concatenation
        };
        
    private:
        std::shared_ptr<Expression> left;
        Operator operator_;
        std::shared_ptr<Expression> right;
        
    public:
        BinaryExpression(std::shared_ptr<Expression> left, Operator op, std::shared_ptr<Expression> right)
            : left(left), operator_(op), right(right) {}
        
        std::shared_ptr<Expression> getLeft() const { return left; }
        Operator getOperator() const { return operator_; }
        std::shared_ptr<Expression> getRight() const { return right; }
        
        std::string toJson() const override {
            std::string opStr;
            switch (operator_) {
                case Operator::EQUALS: opStr = "=="; break;
                case Operator::NOT_EQUALS: opStr = "!="; break;
                case Operator::LESS_THAN: opStr = "<"; break;
                case Operator::GREATER_THAN: opStr = ">"; break;
                case Operator::LESS_EQUALS: opStr = "<="; break;
                case Operator::GREATER_EQUALS: opStr = ">="; break;
                case Operator::AND: opStr = "&&"; break;
                case Operator::OR: opStr = "||"; break;
                case Operator::IS_TYPE: opStr = "is"; break;
                case Operator::IS_NOT_TYPE: opStr = "is not"; break;
                case Operator::CONCATENATE: opStr = "+"; break;
                case Operator::CONTAINS: opStr = "contains"; break;
            }
            
            return "{\"type\":\"BinaryExpression\",\"left\":" + left->toJson() + 
                   ",\"operator\":\"" + opStr + "\",\"right\":" + right->toJson() + "}";
        }
    };