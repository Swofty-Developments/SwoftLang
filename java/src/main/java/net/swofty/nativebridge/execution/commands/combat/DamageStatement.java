package net.swofty.nativebridge.execution.commands.combat;

import net.minestom.server.entity.Entity;
import net.minestom.server.entity.LivingEntity;
import net.minestom.server.entity.damage.Damage;
import net.minestom.server.entity.damage.DamageType;
import net.minestom.server.registry.RegistryKey;
import net.swofty.combat.CombatRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;

/**
 * damage &lt;target&gt; by &lt;amount&gt; [as "&lt;damage_type&gt;"] [from
 * &lt;source&gt;] (was apply_damage). Deals typed damage through the Minestom
 * pipeline (fires EntityDamageEvent, honours i-frames/health). Absent
 * damage_type defaults to minecraft:generic; with a source the damage carries
 * an attacker so death messages + knockback direction resolve.
 */
public class DamageStatement extends AbstractAstNode implements Statement {
    private static final String DEFAULT_DAMAGE_TYPE = "minecraft:generic";

    private final Expression target;
    private final Expression amount;
    private final Expression damageType;
    private final Expression source;

    public DamageStatement(Expression target, Expression amount,
                           Expression damageType, Expression source) {
        this.target = target;
        this.amount = amount;
        this.damageType = damageType;
        this.source = source;
    }

    @Override
    public void execute(ExecutionContext context) {
        LivingEntity victim = CombatRuntime.asLiving(context.evaluate(target),
                "the damage target");
        float value = Coercions.requireNumber(context.evaluate(amount),
                "the damage amount").floatValue();
        String typeName = damageType != null
                ? (String) Coercions.toStringValue(context.evaluate(damageType))
                : DEFAULT_DAMAGE_TYPE;
        RegistryKey<DamageType> typeKey = CombatRuntime.damageTypeKeyFromName(typeName);

        Object src = source != null ? context.evaluate(source) : null;
        if (src == null || NoneValue.isNone(src)) {
            victim.damage(typeKey, value);
            return;
        }
        Entity attacker = CombatRuntime.asEntity(src, "the damage source");
        victim.damage(new Damage(typeKey, attacker, attacker, attacker.getPosition(), value));
    }
}
