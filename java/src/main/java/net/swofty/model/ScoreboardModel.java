package net.swofty.model;

import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * scoreboard "name" { ... } declaration; the lines body is a restricted
 * statement list (line/blank/if/loop) executed per player per cycle
 */
public record ScoreboardModel(
        String name,
        Expression title,
        UpdateCadence update,
        boolean numbersHidden,
        ExecuteBlock lines) {
}
