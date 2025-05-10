package net.swofty.nativebridge.execution;

import java.util.ArrayList;
import java.util.List;

public class BlockStatement implements Statement {
    private final List<Statement> statements = new ArrayList<>();

    public void addStatement(Statement statement) {
        statements.add(statement);
    }

    public List<Statement> getStatements() {
        return statements;
    }
}