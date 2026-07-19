package net.swofty.nativebridge.execution.commands.gui;

import java.util.LinkedHashMap;
import java.util.Map;

import net.minestom.server.entity.Player;
import net.swofty.gui.GuiRuntime;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * open gui "name" to <player> [with { k: v }] (push) and
 * replace gui ... (switch without stacking)
 */
public class OpenGuiStatement extends AbstractAstNode implements Statement {
    private final String guiName;
    private final Expression target;
    private final Map<String, Expression> state;
    private final boolean replace;

    public OpenGuiStatement(String guiName, Expression target,
                            Map<String, Expression> state, boolean replace) {
        this.guiName = guiName;
        this.target = target;
        this.state = state;
        this.replace = replace;
    }

    public String getGuiName() {
        return guiName;
    }

    public Expression getTarget() {
        return target;
    }

    public Map<String, Expression> getState() {
        return state;
    }

    public boolean isReplace() {
        return replace;
    }

    @Override
    public void execute(ExecutionContext context) {
        Player player = context.requirePlayer(context.evaluate(target), "open gui");
        Map<String, Object> stateValues = new LinkedHashMap<>();
        for (Map.Entry<String, Expression> entry : state.entrySet()) {
            stateValues.put(entry.getKey(), context.evaluate(entry.getValue()));
        }
        if (replace) {
            GuiRuntime.replaceGui(player, guiName, stateValues);
        } else {
            GuiRuntime.openGui(player, guiName, stateValues);
        }
    }
}
