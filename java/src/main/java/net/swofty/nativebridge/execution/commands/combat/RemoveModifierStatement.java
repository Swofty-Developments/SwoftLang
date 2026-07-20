package net.swofty.nativebridge.execution.commands.combat;

import net.minestom.server.entity.LivingEntity;
import net.minestom.server.entity.attribute.Attribute;
import net.swofty.combat.CombatRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;

/**
 * remove modifier "&lt;id&gt;" from &lt;e&gt;.&lt;attr&gt; (was
 * remove_attribute_modifier). Drops every modifier on the attribute whose id
 * matches, so it round-trips with add modifier regardless of namespace.
 */
public class RemoveModifierStatement extends AbstractAstNode implements Statement {
    private final Expression id;
    private final Expression entity;
    private final String attribute;

    public RemoveModifierStatement(Expression id, Expression entity, String attribute) {
        this.id = id;
        this.entity = entity;
        this.attribute = attribute;
    }

    @Override
    public void execute(ExecutionContext context) {
        LivingEntity living = CombatRuntime.asLiving(context.evaluate(entity),
                "the modifier target");
        Attribute attr = CombatRuntime.attributeFromName(attribute);
        String modId = CombatRuntime.normalizeModifierId(
                (String) Coercions.toStringValue(context.evaluate(id)));
        CombatRuntime.removeModifierById(living.getAttribute(attr), modId);
    }
}
