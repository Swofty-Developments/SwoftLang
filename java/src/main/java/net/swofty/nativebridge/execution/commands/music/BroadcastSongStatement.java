package net.swofty.nativebridge.execution.commands.music;

import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Player;
import net.swofty.music.MusicRuntime;
import net.swofty.music.NbsSong;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;

/**
 * broadcast song "file.nbs" [volume V] (design 6B): start the song for
 * every online player.
 */
public class BroadcastSongStatement extends AbstractAstNode implements Statement {
    private final Expression song;
    private final Expression volume;

    public BroadcastSongStatement(Expression song, Expression volume) {
        this.song = song;
        this.volume = volume;
    }

    @Override
    public void execute(ExecutionContext context) {
        NbsSong resolved = PlaySongStatement.resolveSong(context, song);
        float startVolume = 1f;
        if (volume != null) {
            startVolume = Coercions.requireNumber(context.evaluate(volume),
                    "the song volume").floatValue();
            if (startVolume > 1f) {
                startVolume /= 100f;
            }
        }
        for (Player player : MinecraftServer.getConnectionManager().getOnlinePlayers()) {
            MusicRuntime.play(player, resolved, 0, startVolume);
        }
    }
}
