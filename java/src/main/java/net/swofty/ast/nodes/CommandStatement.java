package net.swofty.ast.nodes;

import java.util.Map;

/**
 * Base class for all command statements
 */
public abstract class CommandStatement implements Statement {
    protected final Map<String, Expression> arguments;

    protected CommandStatement(Map<String, Expression> arguments) {
        this.arguments = arguments;
    }

    public Map<String, Expression> getArguments() {
        return arguments;
    }

    public abstract String getCommandName();
}