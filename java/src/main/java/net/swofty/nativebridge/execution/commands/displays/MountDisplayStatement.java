package net.swofty.nativebridge.execution.commands.displays;

import net.minestom.server.entity.Entity;
import net.swofty.ScriptError;
import net.swofty.displays.SwoftDisplay;
import net.swofty.mobs.SwoftMob;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * mount display &lt;display&gt; on &lt;entity&gt; (design 6B): passenger mounting;
 * mounting several displays on one anchor forms a display group that
 * moves with it. The anchor may be a player, a mob, or another display.
 */
public class MountDisplayStatement extends AbstractAstNode implements Statement {
    private final Expression display;
    private final Expression anchor;

    public MountDisplayStatement(Expression display, Expression anchor) {
        this.display = display;
        this.anchor = anchor;
    }

    @Override
    public void execute(ExecutionContext context) {
        SwoftDisplay target = ShowDisplayStatement.requireDisplay(
                context.evaluate(display), "mount display");
        Object anchorValue = context.evaluate(anchor);
        Entity anchorEntity;
        if (anchorValue instanceof Entity entity) {
            anchorEntity = entity;
        } else if (anchorValue instanceof SwoftMob mob) {
            anchorEntity = mob;
        } else if (anchorValue instanceof SwoftDisplay other) {
            anchorEntity = other.entity();
        } else {
            throw new ScriptError("mount display expects an entity to mount on, got: "
                    + Values.displayString(anchorValue));
        }
        target.mountOn(anchorEntity);
    }
}
