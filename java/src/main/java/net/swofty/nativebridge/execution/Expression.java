package net.swofty.nativebridge.execution;

import net.swofty.runtime.ExecutionContext;

// Base interface for all expressions
public interface Expression extends ASTNode {
    Object evaluate(ExecutionContext context);
}
