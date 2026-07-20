package net.swofty.nativebridge.execution.commands.npcs;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.npcs.NpcRuntime;
import net.swofty.runtime.ExecutionContext;

/**
 * {@code hide npc "name" from <player|list<Player>|all>} (W-viewers §2). Hides
 * the name-keyed fake player through the same Minestom Viewable remove-viewer
 * mechanism the generic {@code hide <entity>} verb uses.
 */
public class HideNpcStatement extends AbstractAstNode implements Statement {
    private final String name;
    private final Expression target;

    public HideNpcStatement(String name, Expression target) {
        this.name = name;
        this.target = target;
    }

    @Override
    public void execute(ExecutionContext context) {
        NpcRuntime.hide(name, context.evaluate(target));
    }
}
