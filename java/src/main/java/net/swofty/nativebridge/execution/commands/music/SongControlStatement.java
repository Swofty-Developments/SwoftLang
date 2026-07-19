package net.swofty.nativebridge.execution.commands.music;

import net.minestom.server.entity.Player;
import net.swofty.music.MusicRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.PlayerTargets;

/**
 * pause/resume/stop song of &lt;player&gt;, volume of &lt;player&gt; to V, and
 * fade song of &lt;player&gt; to V over N ticks (design 6B) share one node:
 * they all resolve players then poke the session.
 */
public class SongControlStatement extends AbstractAstNode implements Statement {
    public enum Action {
        PAUSE, RESUME, STOP, VOLUME, FADE
    }

    private final Action action;
    private final Expression target;
    /** volume for VOLUME/FADE. */
    private final Expression value;
    /** fade duration in ticks (FADE). */
    private final Expression durationTicks;

    public SongControlStatement(Action action, Expression target, Expression value,
            Expression durationTicks) {
        this.action = action;
        this.target = target;
        this.value = value;
        this.durationTicks = durationTicks;
    }

    @Override
    public void execute(ExecutionContext context) {
        var players = PlayerTargets.resolve(context,
                target != null ? context.evaluate(target) : null,
                action.name().toLowerCase() + " song");
        float volume = 0f;
        if (action == Action.VOLUME || action == Action.FADE) {
            volume = Coercions.requireNumber(context.evaluate(value),
                    "the song volume").floatValue();
            if (volume > 1f) {
                volume /= 100f;
            }
        }
        int ticks = 0;
        if (action == Action.FADE && durationTicks != null) {
            ticks = Coercions.requireNumber(context.evaluate(durationTicks),
                    "the fade duration").intValue();
        }

        for (Player player : players) {
            switch (action) {
                case PAUSE -> MusicRuntime.pause(player);
                case RESUME -> MusicRuntime.resume(player);
                case STOP -> MusicRuntime.stop(player);
                case VOLUME -> MusicRuntime.setVolume(player, volume);
                case FADE -> MusicRuntime.fade(player, volume, ticks);
            }
        }
    }
}
