package net.swofty.nativebridge.execution.commands;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

public class WhileStatement extends AbstractAstNode implements Statement {
    private final Expression condition;
    private final Statement body;

    public WhileStatement(Expression condition, Statement body) {
        this.condition = condition;
        this.body = body;
    }

    public Expression getCondition() {
        return condition;
    }

    public Statement getBody() {
        return body;
    }

    /**
     * Execute a while statement with a runaway guard
     */
    @Override
    public void execute(ExecutionContext context) {
        int iterations = 0;
        while (context.evaluateBoolean(condition)) {
            if (iterations++ >= 100_000) {
                System.err.println("Warning: while loop exceeded 100000 iterations - stopping");
                break;
            }
            context.execute(body);
        }
    }
}
