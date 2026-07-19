package net.swofty.nativebridge.execution.commands;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.minestom.server.command.CommandSender;
import net.swofty.ASTExecutor;
import net.swofty.ScriptError;
import net.swofty.async.AsyncRuntime;
import net.swofty.compiler.SwoftFunction;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.NoneValue;
import net.swofty.runtime.EnvSnapshot;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.SwoftCallable;

/**
 * spawn f(args) — fire-and-forget task; arguments evaluate in the parent
 */
public class SpawnStatement extends AbstractAstNode implements Statement {
    private final String name;
    private final List<Expression> args;

    public SpawnStatement(String name, List<Expression> args) {
        this.name = name;
        this.args = args;
    }

    public String getName() {
        return name;
    }

    public List<Expression> getArgs() {
        return args;
    }

    @Override
    public void execute(ExecutionContext context) {
        CommandSender sender = context.getSender();
        if (context.getVariables().get(name) instanceof SwoftCallable callable) {
            // callable-valued variables shadow declared functions; the task
            // runs the callable rebound over a snapshot of its captured
            // environment, so its writes don't leak back to the parent
            List<Object> values = context.evaluateCallableArgs(callable, args);
            EnvSnapshot snapshot = new EnvSnapshot();
            SwoftCallable task = snapshot.callable(callable);
            values.replaceAll(snapshot::value);
            AsyncRuntime.start("spawn " + name,
                    () -> new ASTExecutor(sender, new HashMap<>())
                            .context().callCallable(task, values));
            return;
        }
        // module-local functions resolve first when spawning inside a module
        SwoftFunction function = context.lookupFunction(name);
        if (function == null) {
            throw new ScriptError("unknown function for spawn: " + name);
        }
        List<Object> values = new ArrayList<>(function.params().size());
        for (int i = 0; i < function.params().size(); i++) {
            values.add(i < args.size()
                    ? context.evaluate(args.get(i)) : NoneValue.INSTANCE);
        }
        EnvSnapshot snapshot = new EnvSnapshot();
        values.replaceAll(snapshot::value);
        Map<String, Object> variables = snapshot.env(context.getVariables());
        AsyncRuntime.start("spawn " + name,
                () -> new ASTExecutor(sender, variables).context()
                        .callUserFunctionWithValues(function, values));
    }
}
