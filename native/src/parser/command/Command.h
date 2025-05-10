#pragma once
#include <string>
#include <vector>
#include <memory>
#include <unordered_map>
#include "Variable.h"
#include "CodeBlock.h"

// Forward declaration
class ExecuteBlock;

class Command {
private:
    std::string name;
    std::string permission;
    std::string description;
    std::vector<std::shared_ptr<Variable>> arguments;
    std::shared_ptr<ExecuteBlock> executeBlock;  // Fix: Add template parameter
    std::unordered_map<std::string, std::string> blocks; // Keep for backward compatibility
    
public:
    Command(const std::string& name) : name(name) {}
    
    const std::string& getName() const {
        return name;
    }
    
    const std::string& getPermission() const {
        return permission;
    }
    
    void setPermission(const std::string& perm) {
        permission = perm;
    }
    
    const std::string& getDescription() const {
        return description;
    }
    
    void setDescription(const std::string& desc) {
        description = desc;
    }
    
    const std::vector<std::shared_ptr<Variable>>& getArguments() const {
        return arguments;
    }
    
    void addArgument(std::shared_ptr<Variable> arg) {
        arguments.push_back(arg);
    }
    
    void setExecuteBlock(std::shared_ptr<ExecuteBlock> block) {  // Fix: Add template parameter
        executeBlock = block;
    }
    
    std::shared_ptr<ExecuteBlock> getExecuteBlock() const {  // Fix: Add template parameter
        return executeBlock;
    }
    
    void addBlock(const std::string& type, const std::string& content) {
        blocks[type] = content;
    }
    
    const std::unordered_map<std::string, std::string>& getBlocks() const {
        return blocks;
    }
    
    // Remove the toJson() method that's causing errors
    // Or implement it properly if needed:
    /*
    std::string toJson() const {
        std::string json = "{\"name\":\"" + name + "\"";
        
        if (!permission.empty()) {
            json += ",\"permission\":\"" + permission + "\"";
        }
        
        if (!description.empty()) {
            json += ",\"description\":\"" + description + "\"";
        }
        
        if (!arguments.empty()) {
            json += ",\"arguments\":[";
            for (size_t i = 0; i < arguments.size(); i++) {
                if (i > 0) json += ",";
                // json += arguments[i]->toJson(); // Uncomment when Variable has toJson()
                json += "{\"placeholder\":\"variable\"}"; // Temporary placeholder
            }
            json += "]";
        }
        
        if (executeBlock != nullptr) {
            json += ",\"executeBlock\":" + executeBlock->toJson();
        }
        
        json += "}";
        return json;
    }
    */
};