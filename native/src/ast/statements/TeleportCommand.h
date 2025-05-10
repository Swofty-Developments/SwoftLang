#pragma once
#include <string>
#include <vector>
#include <memory>
#include <unordered_map>
#include <Statement.h>
#include <Expression.h>

class TeleportCommand : public Statement {
    private:
        std::shared_ptr<Expression> entity;
        std::shared_ptr<Expression> target;
        
    public:
        TeleportCommand(std::shared_ptr<Expression> entity, std::shared_ptr<Expression> target)
            : entity(entity), target(target) {}
        
        std::shared_ptr<Expression> getEntity() const { return entity; }
        std::shared_ptr<Expression> getTarget() const { return target; }
        
        std::string toJson() const override {
            return "{\"type\":\"TeleportCommand\",\"entity\":" + entity->toJson() + 
                   ",\"target\":" + target->toJson() + "}";
        }
    };