package net.swofty.nativebridge.representation;

public class Variable {
    private String name;
    private DataType type;
    private String defaultValue;
    private boolean hasDefault;
    
    public Variable(String name, DataType type) {
        this.name = name;
        this.type = type;
        this.hasDefault = false;
    }
    
    public void setDefault(String value) {
        this.defaultValue = value;
        this.hasDefault = true;
    }
    
    public String getName() {
        return name;
    }
    
    public DataType getType() {
        return type;
    }
    
    public String getDefaultValue() {
        return defaultValue;
    }
    
    public boolean hasDefault() {
        return hasDefault;
    }
}