// Command.h
#pragma once
#include <string>
#include <vector>
#include <unordered_map>
#include <memory>
#include "Variable.h"
#include "CodeBlock.h"

class Command {
private:
    std::string name;
    std::string permission;
    std::string description;
    std::vector<std::shared_ptr<Variable>> arguments;
    std::unordered_map<std::string, std::shared_ptr<CodeBlock>> blocks;

public:
    Command(const std::string& name) : name(name) {}
    
    void setPermission(const std::string& perm) {
        permission = perm;
    }
    
    void setDescription(const std::string& desc) {
        description = desc;
    }
    
    void addArgument(std::shared_ptr<Variable> arg) {
        arguments.push_back(arg);
    }
    
    void addBlock(const std::string& type, const std::string& code) {
        blocks[type] = std::make_shared<CodeBlock>(type, code);
    }
    
    const std::string& getName() const {
        return name;
    }
    
    const std::string& getPermission() const {
        return permission;
    }
    
    const std::string& getDescription() const {
        return description;
    }
    
    const std::vector<std::shared_ptr<Variable>>& getArguments() const {
        return arguments;
    }
    
    const std::unordered_map<std::string, std::shared_ptr<CodeBlock>>& getBlocks() const {
        return blocks;
    }
};