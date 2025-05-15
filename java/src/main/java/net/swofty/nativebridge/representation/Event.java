package net.swofty.nativebridge.representation;

public class Event {
    private String name;
    private int priority;
    private ExecuteBlock executeBlock;

    public Event(String name) {
        this.name = name;
        this.priority = 0;
    }

    public String getName() {
        return name;
    }

    public int getPriority() {
        return priority;
    }

    public void setPriority(int priority) {
        this.priority = priority;
    }

    public ExecuteBlock getExecuteBlock() {
        return executeBlock;
    }

    public void setExecuteBlock(ExecuteBlock executeBlock) {
        this.executeBlock = executeBlock;
    }
}