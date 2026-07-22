package net.swofty.nativebridge.representation;

import java.util.ArrayList;
import java.util.List;

public class DataType {
    private BaseType baseType;
    private List<DataType> subTypes = new ArrayList<>();
    // For BaseType.STRUCT: the nominal type name (e.g. "Guild", "Point") kept
    // verbatim from the compiler so the struct registry can resolve it. null
    // for every builtin base type.
    private String typeName;

    public DataType(BaseType baseType) {
        this.baseType = baseType;
    }

    public DataType(DataType other) {
        this.baseType = other.baseType;
        this.subTypes = other.subTypes;
        this.typeName = other.typeName;
    }

    public void addSubType(DataType subType) {
        this.subTypes.add(subType);
    }

    public BaseType getBaseType() {
        return baseType;
    }

    /** The nominal struct/custom-type name for a STRUCT base; null otherwise. */
    public String getTypeName() {
        return typeName;
    }

    public void setTypeName(String typeName) {
        this.typeName = typeName;
    }

    public List<DataType> getSubTypes() {
        return subTypes;
    }
    
    @Override
    public String toString() {
        if (baseType == BaseType.MAP) {
            return subTypes.isEmpty() ? "map"
                    : "map<" + subTypes.get(0).toString() + ">";
        }

        if (baseType == BaseType.LIST) {
            return subTypes.isEmpty() ? "list"
                    : "list<" + subTypes.get(0).toString() + ">";
        }

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
        
        if (baseType == BaseType.STRUCT) {
            return typeName != null ? typeName : "struct";
        }

        switch (baseType) {
            case STRING: return "String";
            case INTEGER: return "Integer";
            case DOUBLE: return "Double";
            case BOOLEAN: return "Boolean";
            case PLAYER: return "Player";
            case OFFLINE_PLAYER: return "OfflinePlayer";
            case LOCATION: return "Location";
            case BLOCK: return "Block";
            default: return "Unknown";
        }
    }
}