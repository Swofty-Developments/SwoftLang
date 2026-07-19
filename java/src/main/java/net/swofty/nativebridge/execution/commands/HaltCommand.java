package net.swofty.nativebridge.execution.commands;

import net.swofty.async.HaltSignal;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

public class HaltCommand extends AbstractAstNode implements Statement {
    // No additional fields needed

    @Override
    public void execute(ExecutionContext context) {
        throw new HaltSignal();
    }
}
