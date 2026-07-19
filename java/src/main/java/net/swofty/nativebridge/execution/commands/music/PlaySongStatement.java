package net.swofty.nativebridge.execution.commands.music;

import java.util.List;

import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.instance.Instance;
import net.swofty.ScriptError;
import net.swofty.music.MusicRuntime;
import net.swofty.music.NbsSong;
import net.swofty.music.SongRegistry;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.PlayerTargets;
import net.swofty.runtime.Values;

/**
 * play song "file.nbs" to &lt;player|all&gt; [at tick N] [volume V]
 * [in radius R of &lt;location&gt;] (design 6B). The radius form resolves the
 * audience once at start.
 */
public class PlaySongStatement extends AbstractAstNode implements Statement {
    private final Expression song;
    private final Expression target;
    private final Expression atTick;
    private final Expression volume;
    private final Expression radius;
    private final Expression at;

    public PlaySongStatement(Expression song, Expression target, Expression atTick,
            Expression volume, Expression radius, Expression at) {
        this.song = song;
        this.target = target;
        this.atTick = atTick;
        this.volume = volume;
        this.radius = radius;
        this.at = at;
    }

    /** A Song value or a song name resolve to the parsed song. */
    public static NbsSong resolveSong(ExecutionContext context, Expression expression) {
        Object value = context.evaluate(expression);
        if (value instanceof NbsSong resolved) {
            return resolved;
        }
        return SongRegistry.get((String) Coercions.toStringValue(value));
    }

    @Override
    public void execute(ExecutionContext context) {
        NbsSong resolved = resolveSong(context, song);
        int startTick = 0;
        if (atTick != null) {
            startTick = Coercions.requireNumber(context.evaluate(atTick),
                    "the song start tick").intValue();
        }
        float startVolume = 1f;
        if (volume != null) {
            startVolume = Coercions.requireNumber(context.evaluate(volume),
                    "the song volume").floatValue();
            if (startVolume > 1f) {
                startVolume /= 100f; // 0-100 form
            }
        }

        List<Player> audience;
        if (radius != null) {
            double r = Coercions.requireNumber(context.evaluate(radius),
                    "the song radius").doubleValue();
            Object center = at != null ? context.evaluate(at) : null;
            Pos pos;
            Instance instance = null;
            if (center instanceof Pos evaluated) {
                pos = evaluated;
                if (context.getSender() instanceof Player player) {
                    instance = player.getInstance();
                }
            } else if (center == null && context.getSender() instanceof Player player) {
                pos = player.getPosition();
                instance = player.getInstance();
            } else {
                throw new ScriptError("play song in radius expects a location, got: "
                        + Values.displayString(center));
            }
            audience = PlayerTargets.withinRadius(instance, pos, r);
        } else {
            audience = PlayerTargets.resolve(context,
                    target != null ? context.evaluate(target) : null, "play song");
        }

        for (Player player : audience) {
            MusicRuntime.play(player, resolved, startTick, startVolume);
        }
    }
}
