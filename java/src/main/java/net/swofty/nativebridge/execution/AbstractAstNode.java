package net.swofty.nativebridge.execution;

/**
 * Base for all AST nodes: carries the source position emitted by swoftc so
 * runtime errors can cite file line/column.
 */
public abstract class AbstractAstNode implements ASTNode {
    private int line = -1;
    private int col = -1;
    /** Workspace-relative source file (e.g. "scripts/chat.sw"); null off-disk. */
    private String file;
    /** Statement kind tag from swoftc (e.g. "send", "if"); null for expressions. */
    private String kind;

    public int getLine() {
        return line;
    }

    public int getCol() {
        return col;
    }

    public void setSourcePosition(int line, int col) {
        this.line = line;
        this.col = col;
    }

    /** The owning script file, threaded on at load for the debug tracer. */
    public String getFile() {
        return file;
    }

    public void setFile(String file) {
        this.file = file;
    }

    public String getKind() {
        return kind;
    }

    public void setKind(String kind) {
        this.kind = kind;
    }
}
