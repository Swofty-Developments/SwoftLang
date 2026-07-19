package net.swofty.nativebridge.execution.commands.packets;

import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.Map;

import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Player;
import net.minestom.server.network.packet.server.SendablePacket;
import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.packets.PacketSender;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * send packet "Name" { field: expr, ... } to &lt;player|all&gt; (design 5D).
 * Fields are evaluated then coerced through the canonical-record
 * constructor pipeline; Player#sendPacket enqueues, so this is safe from
 * async script contexts too.
 */
public class SendPacketStatement extends AbstractAstNode implements Statement {
    private final String packetName;
    private final Map<String, Expression> fields;
    private final Expression target;

    public SendPacketStatement(String packetName, Map<String, Expression> fields,
            Expression target) {
        this.packetName = packetName;
        this.fields = fields;
        this.target = target;
    }

    @Override
    public void execute(ExecutionContext context) {
        Map<String, Object> values = new LinkedHashMap<>();
        for (Map.Entry<String, Expression> entry : fields.entrySet()) {
            values.put(entry.getKey(), evaluateField(context, entry.getValue()));
        }
        SendablePacket packet = PacketSender.build(packetName, values);

        Object resolved = target != null ? context.evaluate(target) : context.getSender();
        if ("all".equals(resolved)) {
            for (Player player : MinecraftServer.getConnectionManager().getOnlinePlayers()) {
                player.sendPacket(packet);
            }
        } else if (resolved instanceof Player player) {
            player.sendPacket(packet);
        } else if (resolved instanceof Collection<?> collection) {
            for (Object element : collection) {
                if (element instanceof Player player) {
                    player.sendPacket(packet);
                }
            }
        } else {
            throw new ScriptError("send packet expects a player target, got: "
                    + Values.displayString(resolved));
        }
    }

    /** Nested { } objects arrive as expression maps and stay maps. */
    private Object evaluateField(ExecutionContext context, Expression expression) {
        return context.evaluate(expression);
    }
}
