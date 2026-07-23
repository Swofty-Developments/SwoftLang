package net.swofty.mobs.ai;

/**
 * A top-level reusable goal TYPE declaration — {@code goal Chase { ... }}
 * (design v1.9.0 §3). Registered into {@link GoalTypeRegistry} at load and
 * attached to mobs by name via {@link GoalRef}.
 */
public record GoalTypeModel(String name, GoalLifecycle lifecycle) {
}
