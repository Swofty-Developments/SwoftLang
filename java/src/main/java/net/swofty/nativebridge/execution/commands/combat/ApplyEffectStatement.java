package net.swofty.nativebridge.execution.commands.combat;

import net.minestom.server.entity.Entity;
import net.minestom.server.potion.Potion;
import net.minestom.server.potion.PotionEffect;
import net.swofty.combat.CombatRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;

/**
 * apply "&lt;effect&gt;" &lt;amplifier&gt; to &lt;e&gt; for &lt;duration&gt;
 * (was apply_effect). Duration is in ticks. Adds the potion through the same
 * Entity.addEffect the old builtin used.
 */
public class ApplyEffectStatement extends AbstractAstNode implements Statement {
    private final Expression effect;
    private final Expression amplifier;
    private final Expression entity;
    private final Expression duration;

    public ApplyEffectStatement(Expression effect, Expression amplifier,
                                Expression entity, Expression duration) {
        this.effect = effect;
        this.amplifier = amplifier;
        this.entity = entity;
        this.duration = duration;
    }

    @Override
    public void execute(ExecutionContext context) {
        Entity target = CombatRuntime.asEntity(context.evaluate(entity), "the effect target");
        PotionEffect potionEffect = CombatRuntime.potionEffectFromName(
                (String) Coercions.toStringValue(context.evaluate(effect)));
        int amp = Coercions.requireNumber(context.evaluate(amplifier),
                "the effect amplifier").intValue();
        int ticks = Coercions.requireNumber(context.evaluate(duration),
                "the effect duration").intValue();
        target.addEffect(new Potion(potionEffect, amp, ticks));
    }
}
