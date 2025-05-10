#include "DataType.h"

std::shared_ptr<DataType> DataType::fromString(const std::string& typeStr) {
    if (typeStr == "String") {
        return std::make_shared<DataType>(BaseType::STRING);
    } else if (typeStr == "Integer" || typeStr == "int") {
        return std::make_shared<DataType>(BaseType::INTEGER);
    } else if (typeStr == "Double" || typeStr == "double") {
        return std::make_shared<DataType>(BaseType::DOUBLE);
    } else if (typeStr == "Boolean" || typeStr == "bool") {
        return std::make_shared<DataType>(BaseType::BOOLEAN);
    } else if (typeStr == "Player") {
        return std::make_shared<DataType>(BaseType::PLAYER);
    } else if (typeStr == "Location") {
        return std::make_shared<DataType>(BaseType::LOCATION);
    }
    
    return std::make_shared<DataType>(BaseType::UNKNOWN);
}

std::string DataType::toString() const {
    switch (baseType) {
        case BaseType::STRING: return "String";
        case BaseType::INTEGER: return "Integer";
        case BaseType::DOUBLE: return "Double";
        case BaseType::BOOLEAN: return "Boolean";
        case BaseType::PLAYER: return "Player";
        case BaseType::LOCATION: return "Location";
        case BaseType::EITHER: {
            std::string result = "either<";
            for (size_t i = 0; i < subTypes.size(); i++) {
                result += subTypes[i]->toString();
                if (i < subTypes.size() - 1) {
                    result += "|";
                }
            }
            result += ">";
            return result;
        }
        case BaseType::UNKNOWN: return "Unknown";
    }
    
    return "Unknown";
}