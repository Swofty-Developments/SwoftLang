package net.swofty.model;

import java.util.List;
import java.util.Map;

import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * One mob "id" { } declaration (design 5B). The name is an expression so
 * ${mob.health}-style interpolation re-evaluates on every re-render; ai is
 * one of melee | passive | none. Handler blocks run through ASTExecutor
 * with mob (and killer/victim/attacker) bound. onHit fires when a player
 * melee-hits the mob (mob + attacker bound, cancellable).
 */
public record MobDefModel(
        String id,
        String type,
        Expression name,
        double health,
        double damage,
        double speed,
        String ai,
        List<MobDropModel> drops,
        ExecuteBlock onSpawn,
        ExecuteBlock onDeath,
        ExecuteBlock onDamage,
        ExecuteBlock onAttack,
        ExecuteBlock onHit,
        Map<String, InlineHandler> handlers,
        Map<String, MobTagDecl> tags,
        boolean viewable) {

    /** Pre-on_hit shape, kept for existing call sites and smoke tests. */
    public MobDefModel(String id, String type, Expression name, double health,
            double damage, double speed, String ai, List<MobDropModel> drops,
            ExecuteBlock onSpawn, ExecuteBlock onDeath, ExecuteBlock onDamage,
            ExecuteBlock onAttack) {
        this(id, type, name, health, damage, speed, ai, drops,
                onSpawn, onDeath, onDamage, onAttack, null, Map.of());
    }

    /** Pre-inline-handlers shape (on_hit but no generic handlers map). */
    public MobDefModel(String id, String type, Expression name, double health,
            double damage, double speed, String ai, List<MobDropModel> drops,
            ExecuteBlock onSpawn, ExecuteBlock onDeath, ExecuteBlock onDamage,
            ExecuteBlock onAttack, ExecuteBlock onHit) {
        this(id, type, name, health, damage, speed, ai, drops,
                onSpawn, onDeath, onDamage, onAttack, onHit, Map.of());
    }

    /** Pre-typed-tags/viewable shape (handlers but no tags block). */
    public MobDefModel(String id, String type, Expression name, double health,
            double damage, double speed, String ai, List<MobDropModel> drops,
            ExecuteBlock onSpawn, ExecuteBlock onDeath, ExecuteBlock onDamage,
            ExecuteBlock onAttack, ExecuteBlock onHit,
            Map<String, InlineHandler> handlers) {
        this(id, type, name, health, damage, speed, ai, drops,
                onSpawn, onDeath, onDamage, onAttack, onHit, handlers, Map.of(), true);
    }

    /** The generic first-class handler for {@code event}, or null. */
    public InlineHandler handler(String event) {
        return handlers == null ? null : handlers.get(event);
    }
}
