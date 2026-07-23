package net.swofty.mobs.ai;

import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * One target selector declared in an {@code ai { }} block (design v1.9.0 §4).
 * Either a NATURAL-language selector ({@code target closest Player within 16},
 * {@code target last attacker within 24}, {@code target closest Guardian within
 * 10}) or a custom {@code target { ... return <Entity> }} BLOCK selector.
 *
 * <p>Natural forms carry {@code select} (one of {@code player} / {@code hostile}
 * / {@code last_attacker} / {@code mob_type}), a {@code range} expression (in
 * blocks), and — for {@code mob_type} — the {@code mobType} name (a vanilla
 * entity type or a custom mob type name). Block forms carry a statement
 * {@code body} whose {@code return} yields the entity (or none) for the tick.
 */
public record AiTarget(
        String kind,
        String select,
        Expression range,
        String mobType,
        ExecuteBlock body) {

    public static final String NATURAL = "natural";
    public static final String BLOCK = "block";

    public static AiTarget natural(String select, Expression range, String mobType) {
        return new AiTarget(NATURAL, select, range, mobType, null);
    }

    public static AiTarget block(ExecuteBlock body) {
        return new AiTarget(BLOCK, null, null, null, body);
    }

    public boolean isNatural() {
        return NATURAL.equals(kind);
    }
}
