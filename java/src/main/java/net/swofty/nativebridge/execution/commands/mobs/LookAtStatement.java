package net.swofty.nativebridge.execution.commands.mobs;

import net.minestom.server.coordinate.Point;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Entity;
import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * {@code look at <Entity|Location>} (design v1.9.0 §5): faces the goal WITHOUT
 * moving. The subject is the goal's bound {@code mob} (the statement only occurs
 * inside a goal/target body, so it reads the bare-context {@code mob} binding
 * and calls {@link Entity#lookAt}). A {@code none} target is a silent no-op so a
 * {@code look at target} with no current target does nothing.
 */
public class LookAtStatement extends AbstractAstNode implements Statement {
    private final Expression target;

    public LookAtStatement(Expression target) {
        this.target = target;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object subject = context.getVariable("mob");
        if (!(subject instanceof Entity entity)) {
            throw new ScriptError("'look at' has no bound mob to face with "
                    + "(only valid inside a goal/target body)");
        }
        Object goal = context.evaluate(target);
        if (NoneValue.isNone(goal)) {
            return;
        }
        if (goal instanceof Entity targetEntity) {
            entity.lookAt(targetEntity);
        } else if (goal instanceof Pos pos) {
            entity.lookAt(pos);
        } else if (goal instanceof Point point) {
            entity.lookAt(point);
        } else {
            throw new ScriptError("'look at' expects an entity or a location, got: "
                    + Values.displayString(goal));
        }
    }
}
