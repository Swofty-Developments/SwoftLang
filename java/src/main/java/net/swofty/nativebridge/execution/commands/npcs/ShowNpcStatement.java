package net.swofty.nativebridge.execution.commands.npcs;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.npcs.NpcRuntime;
import net.swofty.runtime.ExecutionContext;

/**
 * {@code show npc "name" to <player|list<Player>|all>} (W-viewers §2). Reveals
 * the name-keyed fake player through the same Minestom Viewable add-viewer
 * mechanism the generic {@code show <entity>} verb uses.
 */
public class ShowNpcStatement extends AbstractAstNode implements Statement {
    private final String name;
    private final Expression target;

    public ShowNpcStatement(String name, Expression target) {
        this.name = name;
        this.target = target;
    }

    @Override
    public void execute(ExecutionContext context) {
        NpcRuntime.show(name, context.evaluate(target));
    }
}
