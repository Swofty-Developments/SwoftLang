package net.swofty.nativebridge.representation;

import java.util.ArrayList;
import java.util.List;

public class DataType {
    private BaseType baseType;
    private List<DataType> subTypes = new ArrayList<>();
    
    public DataType(BaseType baseType) {
        this.baseType = baseType;
    }

    public DataType(DataType other) {
        this.baseType = other.baseType;
        this.subTypes = other.subTypes;
    }
    
    public void addSubType(DataType subType) {
        this.subTypes.add(subType);
    }
    
    public BaseType getBaseType() {
        return baseType;
    }
    
    public List<DataType> getSubTypes() {
        return subTypes;
    }
    
    @Override
    public String toString() {
        if (baseType == BaseType.EITHER) {
            StringBuilder sb = new StringBuilder("either<");
            for (int i = 0; i < subTypes.size(); i++) {
                sb.append(subTypes.get(i).toString());
                if (i < subTypes.size() - 1) {
                    sb.append("|");
                }
            }
            sb.append(">");
            return sb.toString();
        }
        
        switch (baseType) {
            case STRING: return "String";
            case INTEGER: return "Integer";
            case DOUBLE: return "Double";
            case BOOLEAN: return "Boolean";
            case PLAYER: return "Player";
            case LOCATION: return "Location";
            default: return "Unknown";
        }
    }
}