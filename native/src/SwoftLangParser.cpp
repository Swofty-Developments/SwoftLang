// SwoftLangParser.cpp - Updated to use ScriptParser
#include "SwoftLangParser.h"
#include "ScriptParser.h"
#include "CommandParser.h"
#include "EventParser.h"
#include "Lexer.h"

std::vector<std::shared_ptr<Command>> SwoftLangParser::parseCommands(const std::string& source) {
    Lexer lexer(source);
    std::vector<Token> tokens = lexer.tokenize();
    
    ScriptParser parser(tokens);
    return parser.parseCommands();
}

std::vector<std::shared_ptr<Event>> SwoftLangParser::parseEvents(const std::string& source) {
    Lexer lexer(source);
    std::vector<Token> tokens = lexer.tokenize();
    
    ScriptParser parser(tokens);
    return parser.parseEvents();
}


std::pair<std::vector<std::shared_ptr<Command>>, std::vector<std::shared_ptr<Event>>> SwoftLangParser::parseAll(const std::string& source) {
    Lexer lexer(source);
    std::vector<Token> tokens = lexer.tokenize();
    
    ScriptParser parser(tokens);
    parser.parseAll(); // Parse both commands and events
    
    return std::make_pair(parser.getCommands(), parser.getEvents());
}

std::string SwoftLangParser::commandsToJson(const std::vector<std::shared_ptr<Command>>& commands) {
    // Existing implementation
    std::string json = "[";
    for (size_t i = 0; i < commands.size(); i++) {
        if (i > 0) json += ",";
        json += commands[i]->toJson();
    }
    json += "]";
    return json;
}