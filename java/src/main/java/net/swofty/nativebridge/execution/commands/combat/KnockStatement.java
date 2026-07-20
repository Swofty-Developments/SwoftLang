package net.swofty.nativebridge.execution.commands.combat;

import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.LivingEntity;
import net.swofty.combat.CombatRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;

/**
 * knock &lt;target&gt; away from &lt;location&gt; [with strength &lt;s&gt;]
 * (was apply_knockback; default strength 0.4). The away direction is
 * (target - location). Minestom's takeKnockback pushes AWAY from the (x, z)
 * vector it is handed, so we pass (location - target) to make the target move
 * along (target - location), i.e. away from the location.
 */
public class KnockStatement extends AbstractAstNode implements Statement {
    private static final float DEFAULT_STRENGTH = 0.4f;

    private final Expression target;
    private final Expression from;
    private final Expression strength;

    public KnockStatement(Expression target, Expression from, Expression strength) {
        this.target = target;
        this.from = from;
        this.strength = strength;
    }

    @Override
    public void execute(ExecutionContext context) {
        LivingEntity victim = CombatRuntime.asLiving(context.evaluate(target),
                "the knockback target");
        Pos origin = (Pos) Coercions.toPos(context.evaluate(from));
        float power = strength != null
                ? Coercions.requireNumber(context.evaluate(strength),
                        "the knockback strength").floatValue()
                : DEFAULT_STRENGTH;

        Pos here = victim.getPosition();
        double x = origin.x() - here.x();
        double z = origin.z() - here.z();
        if (x == 0 && z == 0) {
            // coincident xz: no away-direction to push along
            return;
        }
        victim.takeKnockback(power, x, z);
    }
}
