package net.swofty.nativebridge.execution;

import java.util.ArrayList;
import java.util.List;

import net.swofty.runtime.ExecutionContext;

public class BlockStatement extends AbstractAstNode implements Statement {
    private final List<Statement> statements = new ArrayList<>();

    public void addStatement(Statement statement) {
        statements.add(statement);
    }

    public List<Statement> getStatements() {
        return statements;
    }

    @Override
    public void execute(ExecutionContext context) {
        for (Statement statement : statements) {
            context.execute(statement);
        }
    }
}
