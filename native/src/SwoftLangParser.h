// SwoftLangParser.h
#pragma once
#include <string>
#include <vector>
#include <memory>
#include "Command.h"

class SwoftLangParser {
public:
    static std::vector<std::shared_ptr<Command>> parseCommands(const std::string& source);
    static std::string commandsToJson(const std::vector<std::shared_ptr<Command>>& commands);
};