// SwoftLangParser.cpp
#include "SwoftLangParser.h"
#include "Lexer.h"
#include "CommandParser.h"
#include <sstream>

std::vector<std::shared_ptr<Command>> SwoftLangParser::parseCommands(const std::string& source) {
    // Tokenize the source
    Lexer lexer(source);
    std::vector<Token> tokens = lexer.tokenize();
    
    // Parse the tokens into commands
    CommandParser parser(tokens);
    return parser.parse();
}

std::string SwoftLangParser::commandsToJson(const std::vector<std::shared_ptr<Command>>& commands) {
    std::stringstream json;
    json << "[\n";
    
    for (size_t i = 0; i < commands.size(); i++) {
        auto& cmd = commands[i];
        
        json << "  {\n";
        json << "    \"name\": \"" << cmd->getName() << "\",\n";
        json << "    \"permission\": \"" << cmd->getPermission() << "\",\n";
        json << "    \"description\": \"" << cmd->getDescription() << "\",\n";
        
        // Arguments
        json << "    \"arguments\": [\n";
        const auto& arguments = cmd->getArguments();
        for (size_t j = 0; j < arguments.size(); j++) {
            auto& arg = arguments[j];
            
            json << "      {\n";
            json << "        \"name\": \"" << arg->getName() << "\",\n";
            json << "        \"type\": \"" << arg->getType()->toString() << "\",\n";
            json << "        \"hasDefault\": " << (arg->getHasDefault() ? "true" : "false");
            
            if (arg->getHasDefault()) {
                json << ",\n        \"defaultValue\": \"" << arg->getDefaultValue() << "\"";
            }
            
            json << "\n      }";
            if (j < arguments.size() - 1) {
                json << ",";
            }
            json << "\n";
        }
        json << "    ],\n";
        
        // Blocks
        json << "    \"blocks\": {\n";
        const auto& blocks = cmd->getBlocks();
        bool first = true;
        for (const auto& [blockType, block] : blocks) {
            if (!first) {
                json << ",\n";
            }
            first = false;
            
            // Escape special characters in the code
            std::string escapedCode = block->getCode();
            size_t pos = 0;
            while ((pos = escapedCode.find("\"", pos)) != std::string::npos) {
                escapedCode.replace(pos, 1, "\\\"");
                pos += 2;
            }
            
            pos = 0;
            while ((pos = escapedCode.find("\n", pos)) != std::string::npos) {
                escapedCode.replace(pos, 1, "\\n");
                pos += 2;
            }
            
            json << "      \"";
            json << blockType;
            json << "\": \"";
            json << escapedCode; 
            json << "\"";
        }
        json << "\n    }\n";
        
        json << "  }";
        if (i < commands.size() - 1) {
            json << ",";
        }
        json << "\n";
    }
    
    json << "]\n";
    return json.str();
}