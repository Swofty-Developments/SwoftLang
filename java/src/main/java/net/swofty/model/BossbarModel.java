package net.swofty.model;

import net.swofty.nativebridge.execution.Expression;

/**
 * bossbar "name" { ... }; color is pink|blue|red|green|yellow|purple|white,
 * style is progress|notched_6|notched_10|notched_12|notched_20
 */
public record BossbarModel(
        String name,
        Expression text,
        Expression progress,
        String color,
        String style,
        UpdateCadence update) {
}
