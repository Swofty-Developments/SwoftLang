package net.swofty.nativebridge.representation;

import java.util.ArrayList;
import java.util.List;

/**
 * Represents a SwoftLang command
 */
public class Command {
    private final String name;
    private String permission;
    private String description;
    private final List<Variable> arguments = new ArrayList<>();
    private ExecuteBlock executeBlock;

    public Command(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public String getPermission() {
        return permission;
    }

    public void setPermission(String permission) {
        this.permission = permission;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public List<Variable> getArguments() {
        return arguments;
    }

    public void addArgument(Variable argument) {
        arguments.add(argument);
    }

    /**
     * Get the parsed execute block (AST)
     * @return The execute block, or null if not parsed
     */
    public ExecuteBlock getExecuteBlock() {
        return executeBlock;
    }

    /**
     * Set the parsed execute block (AST)
     * @param executeBlock The parsed execute block
     */
    public void setExecuteBlock(ExecuteBlock executeBlock) {
        this.executeBlock = executeBlock;
    }
}
