package net.swofty.nativebridge.execution.commands.worlds;

import net.minestom.server.coordinate.Pos;
import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;
import net.swofty.worlds.WorldsRuntime;

/**
 * unload world "arena" [without saving] [teleporting players to &lt;loc&gt;]
 * (design 6B).
 */
public class UnloadWorldStatement extends AbstractAstNode implements Statement {
    private final Expression name;
    private final boolean save;
    private final Expression teleportTo;

    public UnloadWorldStatement(Expression name, boolean save, Expression teleportTo) {
        this.name = name;
        this.save = save;
        this.teleportTo = teleportTo;
    }

    @Override
    public void execute(ExecutionContext context) {
        Pos evacuateTo = null;
        if (teleportTo != null) {
            Object where = context.evaluate(teleportTo);
            if (!(where instanceof Pos pos)) {
                throw new ScriptError("unload world expects a location to teleport to, got: "
                        + Values.displayString(where));
            }
            evacuateTo = pos;
        }
        WorldsRuntime.unload(
                WorldStatements.name(context, name, "unload world"), save, evacuateTo);
    }
}
