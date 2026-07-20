package net.swofty.nativebridge.execution.commands.combat;

import net.minestom.server.entity.LivingEntity;
import net.minestom.server.entity.attribute.Attribute;
import net.minestom.server.entity.attribute.AttributeInstance;
import net.minestom.server.entity.attribute.AttributeModifier;
import net.minestom.server.entity.attribute.AttributeOperation;
import net.swofty.combat.CombatRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;

/**
 * add modifier "&lt;id&gt;" to &lt;e&gt;.&lt;attr&gt; of &lt;amount&gt;
 * &lt;operation&gt; (was add_attribute_modifier). Re-adding under the same id is
 * made idempotent by dropping any prior modifier with that id first, then
 * pushing a fresh AttributeModifier through the same AttributeInstance the old
 * builtin used.
 */
public class AddModifierStatement extends AbstractAstNode implements Statement {
    private final Expression id;
    private final Expression entity;
    private final String attribute;
    private final Expression amount;
    private final String operation;

    public AddModifierStatement(Expression id, Expression entity, String attribute,
                                Expression amount, String operation) {
        this.id = id;
        this.entity = entity;
        this.attribute = attribute;
        this.amount = amount;
        this.operation = operation;
    }

    @Override
    public void execute(ExecutionContext context) {
        LivingEntity living = CombatRuntime.asLiving(context.evaluate(entity),
                "the modifier target");
        Attribute attr = CombatRuntime.attributeFromName(attribute);
        String modId = CombatRuntime.normalizeModifierId(
                (String) Coercions.toStringValue(context.evaluate(id)));
        double value = Coercions.requireNumber(context.evaluate(amount),
                "the modifier amount").doubleValue();
        AttributeOperation op = CombatRuntime.attributeOperationFromName(operation);
        AttributeInstance inst = living.getAttribute(attr);
        CombatRuntime.removeModifierById(inst, modId);
        inst.addModifier(new AttributeModifier(modId, value, op));
    }
}
