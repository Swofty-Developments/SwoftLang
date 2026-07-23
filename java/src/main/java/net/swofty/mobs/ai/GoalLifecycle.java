package net.swofty.mobs.ai;

import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * The five GoalSelector lifecycle hooks a scripted goal maps onto (design
 * v1.9.0 §3). {@code shouldStart} / {@code shouldEnd} are Boolean expressions
 * (null =&gt; the GoalSelector default: start true, end false); the three
 * {@code on*} blocks are statement bodies (null =&gt; no-op). Every body runs
 * with the bare-context binding {@code mob} (the enclosing creature) and
 * {@code target} (the group's current target as Optional&lt;Entity&gt;).
 */
public record GoalLifecycle(
        Expression shouldStart,
        ExecuteBlock onStart,
        ExecuteBlock onTick,
        Expression shouldEnd,
        ExecuteBlock onEnd) {
}
