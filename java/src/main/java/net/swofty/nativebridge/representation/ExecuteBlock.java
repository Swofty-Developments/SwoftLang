package net.swofty.nativebridge.representation;

import net.swofty.execution.Statement;

import java.util.ArrayList;
import java.util.List;

/**
 * Represents a block of executable statements in SwoftLang
 */
public class ExecuteBlock {
    private final List<Statement> statements = new ArrayList<>();

    /**
     * Add a statement to this execute block
     * @param statement The statement to add
     */
    public void addStatement(Statement statement) {
        statements.add(statement);
    }

    /**
     * Get all statements in this execute block
     * @return The list of statements
     */
    public List<Statement> getStatements() {
        return statements;
    }

    /**
     * Check if this execute block is empty
     * @return true if no statements, false otherwise
     */
    public boolean isEmpty() {
        return statements.isEmpty();
    }

    /**
     * Get the number of statements in this block
     * @return The statement count
     */
    public int size() {
        return statements.size();
    }
}