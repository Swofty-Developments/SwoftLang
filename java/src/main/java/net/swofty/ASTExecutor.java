package net.swofty;

import java.util.Map;

import net.minestom.server.command.CommandSender;
import net.swofty.async.HaltSignal;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.props.PropertyTables;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.ReturnSignal;
import net.swofty.runtime.Values;

/**
 * Facade over the SwoftLang runtime: owns the ExecutionContext that AST
 * nodes execute themselves against. Property access goes through the
 * PropertyRegistry whitelist; halt unwinds the whole task via HaltSignal.
 */
public class ASTExecutor {
    private final ExecutionContext context;

    static {
        PropertyTables.ensureRegistered();
    }

    public ASTExecutor(CommandSender sender, Map<String, Object> variables) {
        this.context = new ExecutionContext(sender, variables, this, this::emitUi);
    }

    /**
     * The per-task execution context backing this executor
     */
    public ExecutionContext context() {
        return context;
    }

    /**
     * Execute an execute block as a task entry point; halt and top-level
     * return end the task here
     */
    public void execute(ExecuteBlock block) {
        try {
            context.runBlock(block);
        } catch (ReturnSignal ignored) {
        } catch (HaltSignal ignored) {
        }
    }

    /**
     * Evaluate an expression and get its value
     */
    public Object evaluateExpression(Expression expression) {
        return context.evaluate(expression);
    }

    /**
     * Evaluate an expression as a string
     */
    public String evaluateStringExpression(Expression expression) {
        return context.evaluateString(expression);
    }

    public String getDisplayString(Object value) {
        return Values.displayString(value);
    }

    /**
     * Sink for line/entry statements inside scoreboard/tablist DSL bodies;
     * the UI runtime overrides this with a collecting executor
     */
    protected void emitUi(Statement statement) {
        throw new ScriptError(
                "line/entry statements are only valid inside scoreboard or tablist declarations");
    }
}
