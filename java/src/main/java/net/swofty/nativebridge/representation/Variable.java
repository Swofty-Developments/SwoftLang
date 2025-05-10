package net.swofty.nativebridge.representation;

/**
 * Represents a command argument variable
 */
public class Variable {
    private final String name;
    private final DataType type;
    private String defaultValue;
    private boolean hasDefault;

    public Variable(String name, DataType type) {
        this.name = name;
        this.type = type;
        this.hasDefault = false;
    }

    /**
     * Copy constructor
     * @param other The Variable to copy
     */
    public Variable(Variable other) {
        this.name = other.name;
        this.type = new DataType(other.type); // Assuming DataType has a copy constructor
        this.defaultValue = other.defaultValue;
        this.hasDefault = other.hasDefault;
    }

    public String getName() {
        return name;
    }

    public DataType getType() {
        return type;
    }

    public void setDefault(String value) {
        this.defaultValue = value;
        this.hasDefault = true;
    }

    public String getDefaultValue() {
        return defaultValue;
    }

    public boolean hasDefault() {
        return hasDefault;
    }
}