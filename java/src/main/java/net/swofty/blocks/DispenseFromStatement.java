package net.swofty.blocks;

import net.minestom.server.coordinate.Pos;
import net.minestom.server.instance.Instance;
import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.nativebridge.execution.commands.blocks.SetBlockStatement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * dispense from &lt;location&gt; (phase 9 §5): fire the dispenser/dropper block
 * at a location. The world is the sender's world (or the default "world"),
 * matching the other block statements. Errors if the block there is not a
 * dispenser or dropper.
 */
public class DispenseFromStatement extends AbstractAstNode implements Statement {
    private final Expression location;

    public DispenseFromStatement(Expression location) {
        this.location = location;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object where = context.evaluate(location);
        if (!(where instanceof Pos pos)) {
            throw new ScriptError("dispense from expects a location, got: "
                    + Values.displayString(where));
        }
        Instance instance = SetBlockStatement.resolveInstance(context, null, "dispense from");
        DispenserRuntime.dispenseFrom(instance, pos);
    }
}
