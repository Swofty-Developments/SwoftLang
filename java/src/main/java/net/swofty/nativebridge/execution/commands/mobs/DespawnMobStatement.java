package net.swofty.nativebridge.execution.commands.mobs;

import net.swofty.ScriptError;
import net.swofty.mobs.SwoftMob;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * despawn &lt;mob&gt; (design 5B): removes the entity WITHOUT running the death
 * handlers or loot rolls.
 */
public class DespawnMobStatement extends AbstractAstNode implements Statement {
    private final Expression mob;

    public DespawnMobStatement(Expression mob) {
        this.mob = mob;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object resolved = context.evaluate(mob);
        if (resolved instanceof SwoftMob swoftMob) {
            swoftMob.remove();
        } else {
            throw new ScriptError("despawn expects a mob, got: "
                    + Values.displayString(resolved));
        }
    }
}
