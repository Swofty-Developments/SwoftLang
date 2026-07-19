package net.swofty;

/**
 * Runtime script failure (bad coercion, unknown property, invalid argument).
 * Carries the source position of the offending AST node when known.
 */
public class ScriptError extends RuntimeException {
    private final int line;
    private final int col;

    public ScriptError(String message) {
        this(message, -1, -1);
    }

    public ScriptError(String message, int line, int col) {
        super(message);
        this.line = line;
        this.col = col;
    }

    public int getLine() {
        return line;
    }

    public int getCol() {
        return col;
    }

    /**
     * Attach a source position if this error does not carry one yet
     */
    public ScriptError at(int line, int col) {
        if (this.line >= 0 || line < 0) {
            return this;
        }
        ScriptError positioned = new ScriptError(getMessage(), line, col);
        positioned.setStackTrace(getStackTrace());
        return positioned;
    }

    @Override
    public String toString() {
        if (line >= 0) {
            return "ScriptError at " + line + ":" + col + ": " + getMessage();
        }
        return "ScriptError: " + getMessage();
    }
}
