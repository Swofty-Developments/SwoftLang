package net.swofty.mobs.ai;

/**
 * One inline {@code goal "<name>" [priority N] { ... }} inside an {@code ai { }}
 * block (design v1.9.0 §3). {@code priority} is null when unspecified — the
 * binder then falls back to declaration order (see {@link AiBinder}).
 */
public record AiGoal(String name, Integer priority, GoalLifecycle lifecycle) {
}
