package net.swofty.nativebridge.execution.expressions;

import java.util.List;

import net.swofty.compiler.SwoftFunction;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.SwoftCallable;

/**
 * function(p, n) { ... } — evaluates to a SwoftCallable closing over the
 * current variable environment by reference
 */
public class LambdaExpression extends AbstractAstNode implements Expression {
    private final List<SwoftFunction.Param> params;
    private final ExecuteBlock body;
    private final boolean async;

    public LambdaExpression(List<SwoftFunction.Param> params, ExecuteBlock body, boolean async) {
        this.params = params;
        this.body = body;
        this.async = async;
    }

    public List<SwoftFunction.Param> getParams() {
        return params;
    }

    public ExecuteBlock getBody() {
        return body;
    }

    public boolean isAsync() {
        return async;
    }

    @Override
    public Object evaluate(ExecutionContext context) {
        // the defining module travels with the callable so invocations
        // re-enter the same scope instead of re-layering the module env
        return new SwoftCallable(params, body, context.getVariables(), async,
                context.getModule());
    }
}
