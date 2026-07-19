package net.swofty.ui;

import java.util.HashMap;
import java.util.Map;

import net.kyori.adventure.text.Component;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.PlayerSkin;
import net.swofty.ASTExecutor;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.nativebridge.execution.commands.ui.EntryStatement;
import net.swofty.nativebridge.execution.commands.ui.LineStatement;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.props.Coercions;

/**
 * Executes restricted scoreboard lines{} / tablist column{} bodies per
 * player per cycle: line/blank/entry/fill statements emit into the sink,
 * everything else (if/loop) runs through the normal executor.
 */
public class UiBodyExecutor extends ASTExecutor {
    public interface Sink {
        default void line(Component content) {
        }

        default void entry(Component content, PlayerSkin skin) {
        }

        default void fill(PlayerSkin skin) {
        }
    }

    private final Sink sink;

    public UiBodyExecutor(Player player, Sink sink) {
        super(player, initialVars(player));
        this.sink = sink;
    }

    private static Map<String, Object> initialVars(Player player) {
        Map<String, Object> vars = new HashMap<>();
        vars.put("player", player);
        return vars;
    }

    public static void run(Player player, ExecuteBlock body, Sink sink) {
        new UiBodyExecutor(player, sink).execute(body);
    }

    @Override
    protected void emitUi(Statement statement) {
        if (statement instanceof LineStatement line) {
            sink.line(line.isBlank() ? Component.text(" ") : component(line.getText()));
        } else if (statement instanceof EntryStatement entry) {
            PlayerSkin skin = TablistSkins.resolve(entry.getSkin(), this);
            if (entry.isFill()) {
                sink.fill(skin);
            } else {
                sink.entry(component(entry.getText()), skin);
            }
        }
    }

    private Component component(Expression expression) {
        return (Component) Coercions.toComponent(evaluateExpression(expression));
    }
}
