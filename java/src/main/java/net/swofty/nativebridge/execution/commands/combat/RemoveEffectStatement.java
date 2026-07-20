package net.swofty.nativebridge.execution.commands.combat;

import net.minestom.server.entity.Entity;
import net.swofty.combat.CombatRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;

/**
 * remove "&lt;effect&gt;" from &lt;e&gt; (was remove_effect). Clears the potion
 * through the same Entity.removeEffect the old builtin used.
 */
public class RemoveEffectStatement extends AbstractAstNode implements Statement {
    private final Expression effect;
    private final Expression entity;

    public RemoveEffectStatement(Expression effect, Expression entity) {
        this.effect = effect;
        this.entity = entity;
    }

    @Override
    public void execute(ExecutionContext context) {
        Entity target = CombatRuntime.asEntity(context.evaluate(entity), "the effect target");
        target.removeEffect(CombatRuntime.potionEffectFromName(
                (String) Coercions.toStringValue(context.evaluate(effect))));
    }
}
