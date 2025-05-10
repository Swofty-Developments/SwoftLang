#pragma once
#include <string>
#include <vector>
#include <memory>

enum class BaseType {
    STRING,
    INTEGER,
    DOUBLE,
    BOOLEAN,
    PLAYER,
    LOCATION,
    EITHER,
    UNKNOWN
};

class DataType {
private:
    BaseType baseType;
    std::vector<std::shared_ptr<DataType>> subTypes;

public:
    DataType(BaseType type) : baseType(type) {}

    static std::shared_ptr<DataType> fromString(const std::string& typeStr);
    
    void addSubType(std::shared_ptr<DataType> subType) {
        subTypes.push_back(subType);
    }
    
    BaseType getBaseType() const {
        return baseType;
    }
    
    const std::vector<std::shared_ptr<DataType>>& getSubTypes() const {
        return subTypes;
    }
    
    std::string toString() const;
};