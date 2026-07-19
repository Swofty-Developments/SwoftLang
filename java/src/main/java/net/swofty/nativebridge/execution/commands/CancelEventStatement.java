package net.swofty.nativebridge.execution.commands;

import net.swofty.event.AbstractSwoftEvent;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

public class CancelEventStatement extends AbstractAstNode implements Statement {
    // Empty statement - just marks that the event should be cancelled

    /**
     * Execute a cancel event statement
     */
    @Override
    public void execute(ExecutionContext context) {
        Object event = context.getVariables().get("event");
        if (event instanceof AbstractSwoftEvent<?> wrapper) {
            wrapper.cancel();
        } else {
            System.err.println("Error: Cannot cancel event - no event object found");
        }
    }
}
