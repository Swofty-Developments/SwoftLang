#pragma once
#include <string>

class CodeBlock {
private:
    std::string blockType;
    std::string code;

public:
    CodeBlock(const std::string& type, const std::string& code)
        : blockType(type), code(code) {}
    
    const std::string& getType() const {
        return blockType;
    }
    
    const std::string& getCode() const {
        return code;
    }
};