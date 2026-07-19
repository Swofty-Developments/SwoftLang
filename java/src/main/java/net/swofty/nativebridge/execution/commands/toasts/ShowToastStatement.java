package net.swofty.nativebridge.execution.commands.toasts;

import net.kyori.adventure.text.Component;
import net.minestom.server.advancements.FrameType;
import net.minestom.server.advancements.Notification;
import net.minestom.server.entity.Player;
import net.minestom.server.item.Material;
import net.swofty.ScriptError;
import net.swofty.TextFormat;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.PlayerTargets;

/**
 * show toast "&lt;title&gt;" [description ...] icon "DIAMOND"
 * frame task|goal|challenge to &lt;player&gt; (design 6D): the pinned
 * Minestom notification API (Notification add+remove packets). The
 * toast renders the title line only, so a description folds onto a
 * second line of the title component.
 */
public class ShowToastStatement extends AbstractAstNode implements Statement {
    private final Expression title;
    private final Expression description;
    private final Expression icon;
    private final String frame;
    private final Expression target;

    public ShowToastStatement(Expression title, Expression description, Expression icon,
            String frame, Expression target) {
        this.title = title;
        this.description = description;
        this.icon = icon;
        this.frame = frame;
        this.target = target;
    }

    @Override
    public void execute(ExecutionContext context) {
        Component text = TextFormat.component(context.evaluateString(title));
        if (description != null) {
            text = text.append(Component.newline())
                    .append(TextFormat.component(context.evaluateString(description)));
        }

        Material material = Material.DIAMOND;
        if (icon != null) {
            material = Coercions.toMaterial(context.evaluate(icon));
        }

        FrameType frameType = FrameType.TASK;
        if (frame != null) {
            try {
                frameType = FrameType.valueOf(frame.toUpperCase());
            } catch (IllegalArgumentException e) {
                throw new ScriptError("unknown toast frame '" + frame
                        + "' (valid: task, goal, challenge)");
            }
        }

        Notification notification = new Notification(text, frameType, material);
        var addPacket = notification.buildAddPacket();
        var removePacket = notification.buildRemovePacket();
        for (Player player : PlayerTargets.resolve(context,
                target != null ? context.evaluate(target) : null, "show toast")) {
            player.sendPacket(addPacket);
            player.sendPacket(removePacket);
        }
    }
}
