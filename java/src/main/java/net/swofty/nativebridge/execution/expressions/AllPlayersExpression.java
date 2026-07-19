package net.swofty.nativebridge.execution.expressions;

import net.minestom.server.MinecraftServer;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ExecutionContext;

public class AllPlayersExpression extends AbstractAstNode implements Expression {
    // Evaluates to the collection of online players

    @Override
    public Object evaluate(ExecutionContext context) {
        return MinecraftServer.getConnectionManager().getOnlinePlayers();
    }
}
