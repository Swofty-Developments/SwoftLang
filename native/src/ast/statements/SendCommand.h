#pragma once
#include <string>
#include <vector>
#include <memory>
#include <unordered_map>
#include <Statement.h>
#include <Expression.h>

class SendCommand : public Statement {
    private:
        std::shared_ptr<Expression> message;
        std::shared_ptr<Expression> target;
        
    public:
        SendCommand(std::shared_ptr<Expression> message, std::shared_ptr<Expression> target = nullptr)
            : message(message), target(target) {}
        
        std::shared_ptr<Expression> getMessage() const { return message; }
        std::shared_ptr<Expression> getTarget() const { return target; }
        
        std::string toJson() const override {
            std::string json = "{\"type\":\"SendCommand\",\"message\":" + message->toJson();
            if (target) {
                json += ",\"target\":" + target->toJson();
            }
            json += "}";
            return json;
        }
    };
