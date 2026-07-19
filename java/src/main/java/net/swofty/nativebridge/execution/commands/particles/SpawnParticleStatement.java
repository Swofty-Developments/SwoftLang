package net.swofty.nativebridge.execution.commands.particles;

import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.network.packet.server.play.ParticlePacket;
import net.minestom.server.particle.Particle;
import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.PlayerTargets;
import net.swofty.runtime.Values;

/**
 * spawn particle "FLAME" at &lt;loc&gt; [count N] [offset x,y,z] [speed S]
 * [to &lt;viewer|all&gt;] (design 6D): a first-class ParticlePacket wrapper.
 */
public class SpawnParticleStatement extends AbstractAstNode implements Statement {
    private final Expression particle;
    private final Expression at;
    private final Expression count;
    private final Expression offsetX;
    private final Expression offsetY;
    private final Expression offsetZ;
    private final Expression speed;
    private final Expression viewer;

    public SpawnParticleStatement(Expression particle, Expression at, Expression count,
            Expression offsetX, Expression offsetY, Expression offsetZ,
            Expression speed, Expression viewer) {
        this.particle = particle;
        this.at = at;
        this.count = count;
        this.offsetX = offsetX;
        this.offsetY = offsetY;
        this.offsetZ = offsetZ;
        this.speed = speed;
        this.viewer = viewer;
    }

    @Override
    public void execute(ExecutionContext context) {
        String name = (String) Coercions.toStringValue(context.evaluate(particle));
        String key = name.contains(":") ? name.toLowerCase() : "minecraft:" + name.toLowerCase();
        Particle resolved = Particle.fromKey(key);
        if (resolved == null) {
            throw new ScriptError("unknown particle '" + name + "'");
        }

        Object where = context.evaluate(at);
        if (!(where instanceof Pos pos)) {
            throw new ScriptError("spawn particle expects a location, got: "
                    + Values.displayString(where));
        }

        int particleCount = count != null
                ? Coercions.requireNumber(context.evaluate(count), "the particle count")
                        .intValue()
                : 1;
        float ox = floatOf(context, offsetX);
        float oy = floatOf(context, offsetY);
        float oz = floatOf(context, offsetZ);
        float maxSpeed = speed != null
                ? Coercions.requireNumber(context.evaluate(speed), "the particle speed")
                        .floatValue()
                : 0f;

        ParticlePacket packet = new ParticlePacket(resolved,
                pos.x(), pos.y(), pos.z(), ox, oy, oz, maxSpeed, particleCount);
        for (Player player : PlayerTargets.resolve(context,
                viewer != null ? context.evaluate(viewer) : "all", "spawn particle")) {
            player.sendPacket(packet);
        }
    }

    private static float floatOf(ExecutionContext context, Expression expression) {
        return expression != null
                ? Coercions.requireNumber(context.evaluate(expression),
                        "a particle offset").floatValue()
                : 0f;
    }
}
