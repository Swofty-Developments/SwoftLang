package net.swofty.nativebridge.execution.commands;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

public class IfStatement extends AbstractAstNode implements Statement {
    private final Expression condition;
    private final Statement thenStatement;
    private final Statement elseStatement;

    public IfStatement(Expression condition, Statement thenStatement, Statement elseStatement) {
        this.condition = condition;
        this.thenStatement = thenStatement;
        this.elseStatement = elseStatement;
    }

    public Expression getCondition() {
        return condition;
    }

    public Statement getThenStatement() {
        return thenStatement;
    }

    public Statement getElseStatement() {
        return elseStatement;
    }

    /**
     * Execute an if statement
     */
    @Override
    public void execute(ExecutionContext context) {
        boolean conditionResult = context.evaluateBoolean(condition);

        if (conditionResult) {
            context.execute(thenStatement);
        } else if (elseStatement != null) {
            context.execute(elseStatement);
        }
    }
}
