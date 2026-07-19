package net.swofty.model;

import java.util.List;

import net.swofty.nativebridge.execution.Expression;

/**
 * item { ... } body inside gui declarations; material XOR skull is enforced
 * by the checker
 */
public record ItemSpecModel(
        Expression material,
        Expression skull,
        Expression name,
        List<Expression> lore,
        Expression amount,
        Expression glint) {
}
