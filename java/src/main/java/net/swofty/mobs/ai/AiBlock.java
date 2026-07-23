package net.swofty.mobs.ai;

import java.util.List;

/**
 * The parsed {@code ai { }} block on a mob declaration (design v1.9.0 §2): the
 * ordered target selectors, the inline goals, and the reusable goal-type
 * references. One {@code ai { }} block becomes one Minestom {@code
 * EntityAIGroup} (see {@link AiBinder}).
 */
public record AiBlock(
        List<AiTarget> targets,
        List<AiGoal> goals,
        List<GoalRef> goalRefs) {
}
