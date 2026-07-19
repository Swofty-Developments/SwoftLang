package net.swofty.nativebridge.execution.commands;

import java.util.Collection;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.minimessage.MiniMessage;
import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.swofty.TextFormat;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.nativebridge.execution.expressions.BinaryExpression;
import net.swofty.nativebridge.execution.expressions.StringLiteral;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Interpolator;
import net.swofty.runtime.Values;

public class SendCommand extends AbstractAstNode implements Statement {
    private final Expression message;
    private final Expression target;

    public SendCommand(Expression message, Expression target) {
        this.message = message;
        this.target = target;
    }

    public Expression getMessage() {
        return message;
    }

    public Expression getTarget() {
        return target;
    }

    /**
     * Execute a send command
     */
    @Override
    public void execute(ExecutionContext context) {
        // Build the MiniMessage source so that ONLY tags authored in the
        // script's own string literals are parsed as markup; every interpolated
        // (${...}) or otherwise computed value is spliced in as escaped plain
        // text. Without this, user-controlled data (e.g. raw player chat in
        // `send "You said: ${event.message}"`, and `broadcast "${event.message}"`
        // which relays it server-wide) would be parsed as MiniMessage and could
        // inject decoration, staff-prefix spoofing, and interactive
        // click/hover/run_command/insertion tags.
        String text = buildSafe(context, message);
        Object resolved = target != null ? context.evaluate(target) : context.getSender();

        // Render through TextFormat (MiniMessage) so <yellow>/<bold>/</white>
        // and the other tags become a real Component, instead of the legacy
        // Values.formatColorCodes string path that only mapped a handful of
        // <color> tags to section codes and dropped <bold>/closing tags.
        Component component = TextFormat.component(text);

        CommandSender sender = context.getSender();
        if (NoneValue.isNone(resolved) || resolved == sender || resolved.equals("sender")) {
            sender.sendMessage(component);
        } else if (resolved.equals("all")) {
            // Send to all players
            for (Player player : MinecraftServer.getConnectionManager().getOnlinePlayers()) {
                player.sendMessage(component);
            }
        } else if (resolved instanceof Player) {
            ((Player) resolved).sendMessage(component);
        } else if (resolved instanceof Collection) {
            for (Object element : (Collection<?>) resolved) {
                if (element instanceof Player) {
                    ((Player) element).sendMessage(component);
                }
            }
        } else {
            sender.sendMessage("Error: Cannot send message to " + resolved);
        }
    }

    /**
     * Build the MiniMessage source for the message expression, keeping tags
     * authored in string literals live while inserting every interpolated /
     * computed value as escaped plain text.
     *
     * <p>Non-path {@code ${...}} interpolation is desugared by the compiler into
     * {@code CONCATENATE} binaries whose string-literal segments still carry the
     * author's markup, so we recurse through those and only escape the computed
     * operands. Any other expression (a variable, call, {@code otherwise}, or an
     * {@code ADD} that may be numeric arithmetic) is evaluated whole and escaped
     * as data — mirroring the previous {@code evaluateString} rendering exactly,
     * so tag-free output stays byte-for-byte identical.
     */
    private static String buildSafe(ExecutionContext context, Expression expr) {
        if (expr instanceof StringLiteral literal) {
            return Interpolator.interpolate(context, literal.getValue(), SendCommand::escape);
        }
        if (expr instanceof BinaryExpression binary
                && binary.getOperator() == BinaryExpression.Operator.CONCATENATE) {
            return buildSafe(context, binary.getLeft())
                    + buildSafe(context, binary.getRight());
        }
        Object value = context.evaluate(expr);
        String rendered = NoneValue.isNone(value) ? "" : Values.displayString(value);
        return escape(rendered);
    }

    /** Escape MiniMessage tags so a data value can only contribute plain text. */
    private static String escape(String value) {
        return MiniMessage.miniMessage().escapeTags(value);
    }
}
