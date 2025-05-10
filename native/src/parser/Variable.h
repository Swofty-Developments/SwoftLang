// Add this to your Variable.h file:

#pragma once
#include <string>
#include <memory>
#include "DataType.h"

class Variable {
private:
    std::string name;
    std::shared_ptr<DataType> type;
    std::string defaultValue;
    bool hasDefault;

public:
    Variable(const std::string& name, std::shared_ptr<DataType> type)
        : name(name), type(type), hasDefault(false) {}
    
    void setDefault(const std::string& value) {
        defaultValue = value;
        hasDefault = true;
    }
    
    const std::string& getName() const {
        return name;
    }
    
    const std::shared_ptr<DataType>& getType() const {
        return type;
    }
    
    const std::string& getDefaultValue() const {
        return defaultValue;
    }
    
    bool getHasDefault() const {
        return hasDefault;
    }
    
    std::string toJson() const {
        std::string json = "{\"name\":\"" + name + "\",\"type\":" + type->toString();
        if (hasDefault) {
            json += ",\"default\":\"" + defaultValue + "\"";
        }
        json += "}";
        return json;
    }
};