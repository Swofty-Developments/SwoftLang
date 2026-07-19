package net.swofty.nativebridge.execution.expressions;

import net.swofty.model.StorageBackendModel;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ExecutionContext;
import net.swofty.worlds.PolarStorageWorldLoader;

/**
 * polar_storage_loader(&lt;backend config&gt;) (design 6B): the backend block
 * is parsed with the storage{} syntax and arrives as a structured
 * backend object; evaluation resolves the shared cached loader over
 * that SwoftStorage backend.
 */
public class LoaderStorageExpression extends AbstractAstNode implements Expression {
    private final StorageBackendModel backend;

    public LoaderStorageExpression(StorageBackendModel backend) {
        this.backend = backend;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        return PolarStorageWorldLoader.of(backend);
    }
}
