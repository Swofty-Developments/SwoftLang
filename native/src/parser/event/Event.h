#pragma once
#include <string>
#include <memory>
#include "ExecuteBlock.h"

class Event {
private:
    std::string name;
    int priority;
    std::shared_ptr<ExecuteBlock> executeBlock;

public:
    Event(const std::string& name) : name(name), priority(0) {}
    
    const std::string& getName() const { return name; }
    
    int getPriority() const { return priority; }
    void setPriority(int value) { priority = value; }
    
    const std::shared_ptr<ExecuteBlock>& getExecuteBlock() const { return executeBlock; }
    void setExecuteBlock(std::shared_ptr<ExecuteBlock> block) { executeBlock = block; }
    
    std::string toJson() const {
        std::string json = "{";
        json += "\"name\":\"" + name + "\",";
        json += "\"priority\":" + std::to_string(priority);
        if (executeBlock) {
            json += ",\"executeBlock\":" + executeBlock->toJson();
        }
        json += "}";
        return json;
    }
};