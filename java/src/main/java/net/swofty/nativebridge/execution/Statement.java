package net.swofty.nativebridge.execution;

import net.swofty.runtime.ExecutionContext;

// Base interface for all statements
public interface Statement extends ASTNode {
    void execute(ExecutionContext context);
}
