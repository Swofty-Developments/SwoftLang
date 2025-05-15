// SwoftLangParser.h
#pragma once
#include <string>
#include <vector>
#include <memory>
#include "Command.h"
#include "Event.h" 

class SwoftLangParser {
public:
    static std::vector<std::shared_ptr<Command>> parseCommands(const std::string& source);
    static std::vector<std::shared_ptr<Event>> parseEvents(const std::string& source);
    static std::pair<std::vector<std::shared_ptr<Command>>, std::vector<std::shared_ptr<Event>>> parseAll(const std::string &source);
    static std::string commandsToJson(const std::vector<std::shared_ptr<Command>> &commands);
};