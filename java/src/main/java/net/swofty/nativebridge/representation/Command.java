package net.swofty.nativebridge.representation;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Command {
    private String name;
    private String permission;
    private String description;
    private List<Variable> arguments = new ArrayList<>();
    private Map<String, CodeBlock> blocks = new HashMap<>();
    
    public Command(String name) {
        this.name = name;
    }
    
    public void setPermission(String permission) {
        this.permission = permission;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public void addArgument(Variable argument) {
        this.arguments.add(argument);
    }
    
    public void addBlock(String type, String code) {
        this.blocks.put(type, new CodeBlock(type, code));
    }
    
    public String getName() {
        return name;
    }
    
    public String getPermission() {
        return permission;
    }
    
    public String getDescription() {
        return description;
    }
    
    public List<Variable> getArguments() {
        return arguments;
    }
    
    public Map<String, CodeBlock> getBlocks() {
        return blocks;
    }
}