package net.swofty.nativebridge.representation;

import net.swofty.nativebridge.execution.Statement;

import java.util.ArrayList;
import java.util.List;

/**
 * Represents a block of executable statements in SwoftLang
 */
public class ExecuteBlock {
    private final List<Statement> statements = new ArrayList<>();
    private boolean async = false;
    /**
     * Owning module name for blocks loaded from a module bundle (null for
     * flat scripts). Execution contexts entering a tagged block resolve
     * module-private functions and see the module's variable environment.
     */
    private String module;
    /**
     * Debug-tracer handler identity for top-level handler bodies (command /
     * event execute blocks): the display name (e.g. "event PlayerChat"), the
     * owning file, and the declaration line. Null for non-handler blocks
     * (function/lambda bodies, nested blocks) so they emit no handler event.
     */
    private String handlerName;
    private String file;
    private int handlerLine = -1;

    public boolean isAsync() {
        return async;
    }

    public void setAsync(boolean async) {
        this.async = async;
    }

    public String getModule() {
        return module;
    }

    public void setModule(String module) {
        this.module = module;
    }

    /**
     * Tag this block as a named handler body for the debug tracer.
     * @param name display name (e.g. "command tp", "event PlayerChat")
     * @param file owning workspace-relative file
     * @param line handler declaration line
     */
    public void setHandler(String name, String file, int line) {
        this.handlerName = name;
        this.file = file;
        this.handlerLine = line;
    }

    /** Handler display name, or null when this block is not a handler body. */
    public String getHandlerName() {
        return handlerName;
    }

    public String getFile() {
        return file;
    }

    public int getHandlerLine() {
        return handlerLine;
    }

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