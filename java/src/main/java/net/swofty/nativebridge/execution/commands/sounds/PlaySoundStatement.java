package net.swofty.nativebridge.execution.commands.sounds;

import net.kyori.adventure.key.Key;
import net.kyori.adventure.sound.Sound;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.PlayerTargets;

/**
 * play sound "minecraft:entity.ender_dragon.growl" to &lt;target&gt;
 * [at &lt;loc&gt;] [volume V] [pitch P] (design 6D). Adventure Sound API;
 * without a location the sound follows the hearing player.
 */
public class PlaySoundStatement extends AbstractAstNode implements Statement {
    private final Expression sound;
    private final Expression target;
    private final Expression at;
    private final Expression volume;
    private final Expression pitch;

    public PlaySoundStatement(Expression sound, Expression target, Expression at,
            Expression volume, Expression pitch) {
        this.sound = sound;
        this.target = target;
        this.at = at;
        this.volume = volume;
        this.pitch = pitch;
    }

    static Key soundKey(String name) {
        String key = name.contains(":") ? name.toLowerCase() : "minecraft:" + name.toLowerCase();
        try {
            return Key.key(key);
        } catch (Exception e) {
            throw new ScriptError("invalid sound name '" + name + "'");
        }
    }

    @Override
    public void execute(ExecutionContext context) {
        Key key = soundKey((String) Coercions.toStringValue(context.evaluate(sound)));
        float soundVolume = volume != null
                ? Coercions.requireNumber(context.evaluate(volume), "the sound volume")
                        .floatValue()
                : 1f;
        float soundPitch = pitch != null
                ? Coercions.requireNumber(context.evaluate(pitch), "the sound pitch")
                        .floatValue()
                : 1f;
        Sound adventure = Sound.sound(key, Sound.Source.MASTER, soundVolume, soundPitch);

        Pos position = null;
        if (at != null) {
            Object where = context.evaluate(at);
            if (!(where instanceof Pos pos)) {
                throw new ScriptError("play sound at expects a location, got: " + where);
            }
            position = pos;
        }

        for (Player player : PlayerTargets.resolve(context,
                target != null ? context.evaluate(target) : null, "play sound")) {
            if (position != null) {
                player.playSound(adventure, position.x(), position.y(), position.z());
            } else {
                player.playSound(adventure, Sound.Emitter.self());
            }
        }
    }
}
