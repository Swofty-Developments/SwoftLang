package net.swofty.nativebridge.representation;

import java.util.List;

public class Event {
    private String name;
    private int priority;
    private ExecuteBlock executeBlock;

    /**
     * OOP receiver model: the Capitalized base type this handler belongs to
     * ("Player" / "Entity" / "Mob" / "Item" / "Block" / "Projectile" /
     * "Inventory" / "World" / "Server"), or {@code null} for a legacy flat
     * {@code event {}} / {@code on {}} handler. When set, the runtime binds
     * {@code this} to the receiver instance and the {@link #params} positionally
     * instead of the flat sender/event/alias scheme.
     */
    private String receiver;

    /**
     * The user's positional binder names for a receiver method (empty for a
     * flat handler). {@code on_hit(attacker)} emits {@code ["attacker"]}; each
     * name binds to the mapped event argument in order.
     */
    private List<String> params = List.of();

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

    /** The receiver base type, or {@code null} for a flat handler. */
    public String getReceiver() {
        return receiver;
    }

    public void setReceiver(String receiver) {
        this.receiver = receiver;
    }

    /** True when this handler is an OOP receiver method (has a receiver type). */
    public boolean isReceiver() {
        return receiver != null;
    }

    /** The positional binder names for a receiver method. */
    public List<String> getParams() {
        return params;
    }

    public void setParams(List<String> params) {
        this.params = params != null ? params : List.of();
    }
}
