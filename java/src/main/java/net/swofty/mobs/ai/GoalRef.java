package net.swofty.mobs.ai;

/**
 * A reference to a reusable top-level goal TYPE attached through
 * {@code goals: [ Chase priority 1, Wander ]} (design v1.9.0 §3). The lifecycle
 * is resolved from {@link GoalTypeRegistry} at bind time; {@code priority} is
 * null when unspecified.
 */
public record GoalRef(String name, Integer priority) {
}
