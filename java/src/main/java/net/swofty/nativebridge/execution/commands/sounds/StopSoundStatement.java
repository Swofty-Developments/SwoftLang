package net.swofty.nativebridge.execution.commands.sounds;

import net.kyori.adventure.sound.SoundStop;
import net.minestom.server.entity.Player;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.PlayerTargets;

/**
 * stop sound ["name"] for &lt;target&gt; (design 6D): named stop, or all
 * sounds when no name is given.
 */
public class StopSoundStatement extends AbstractAstNode implements Statement {
    private final Expression sound;
    private final Expression target;

    public StopSoundStatement(Expression sound, Expression target) {
        this.sound = sound;
        this.target = target;
    }

    @Override
    public void execute(ExecutionContext context) {
        SoundStop stop = sound != null
                ? SoundStop.named(PlaySoundStatement.soundKey(
                        (String) Coercions.toStringValue(context.evaluate(sound))))
                : SoundStop.all();
        for (Player player : PlayerTargets.resolve(context,
                target != null ? context.evaluate(target) : null, "stop sound")) {
            player.stopSound(stop);
        }
    }
}
