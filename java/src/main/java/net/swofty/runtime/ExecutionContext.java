package net.swofty.runtime;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.swofty.ASTExecutor;
import net.swofty.ScriptError;
import net.swofty.async.AsyncRuntime;
import net.swofty.compiler.FunctionRegistry;
import net.swofty.compiler.ModuleRegistry;
import net.swofty.compiler.SwoftFunction;
import net.swofty.debug.DebugServer;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.persist.PersistStore;
import net.swofty.props.NoneValue;
import net.swofty.props.PathResolver;

/**
 * Per-task execution state: the variable environment, the sender, and the
 * accessors nodes need to run themselves. Statements/expressions receive a
 * context and own their semantics; the owning ASTExecutor facade supplies
 * the line/entry sink so UI body executors can collect instead of throw.
 */
public final class ExecutionContext {
    private static final int MAX_CALL_DEPTH = 256;
    private static final ThreadLocal<Integer> callDepth = ThreadLocal.withInitial(() -> 0);

    /**
     * Sink for line/entry statements inside scoreboard/tablist DSL bodies
     */
    public interface UiEmitter {
        void emit(Statement statement);
    }

    private final CommandSender sender;
    private Map<String, Object> variables;
    private final ASTExecutor executor;
    private final UiEmitter uiEmitter;
    /** Module whose scope this context runs in (null outside modules). */
    private String module;

    public ExecutionContext(CommandSender sender, Map<String, Object> variables,
            ASTExecutor executor, UiEmitter uiEmitter) {
        this.sender = sender;
        this.variables = variables != null ? variables : new HashMap<>();
        this.executor = executor;
        this.uiEmitter = uiEmitter;
        if (this.variables instanceof ScopedVariables scoped && scoped.moduleName() != null) {
            this.module = scoped.moduleName();
        }

        if (!this.variables.containsKey("sender")) {
            this.variables.put("sender", sender);
        }
    }

    public String getModule() {
        return module;
    }

    public void setModule(String module) {
        this.module = module;
    }

    public CommandSender getSender() {
        return sender;
    }

    public Map<String, Object> getVariables() {
        return variables;
    }

    /**
     * The facade that owns this context; gui/ui helpers evaluate their
     * sub-expressions through it
     */
    public ASTExecutor getExecutor() {
        return executor;
    }

    public void runBlock(ExecuteBlock block) {
        enterModule(block);
        // debug tracer: a named block is a command/event handler body — bracket
        // its statements with handler enter/exit and set the current-handler tag
        // that per-statement traces carry. Non-handler blocks (function/lambda
        // bodies) have no name and keep the calling handler's tag.
        String handlerName = DebugServer.enabled ? block.getHandlerName() : null;
        if (handlerName == null) {
            for (Statement statement : block.getStatements()) {
                execute(statement);
            }
            return;
        }
        String previousHandler = DebugServer.currentHandler();
        DebugServer.setCurrentHandler(handlerName);
        DebugServer.handlerEvent("enter", handlerName, block.getFile(), block.getHandlerLine());
        try {
            for (Statement statement : block.getStatements()) {
                execute(statement);
            }
        } finally {
            DebugServer.handlerEvent("exit", handlerName, block.getFile(), block.getHandlerLine());
            DebugServer.setCurrentHandler(previousHandler);
        }
    }

    /**
     * Blocks loaded from a module bundle carry their owning module: entering
     * one from a module-less context (command/event/gui handlers built by
     * the various runtimes) adopts the module scope, layering the existing
     * bindings locally over the module's live variable environment so module
     * vars read and write through while handler bindings stay task-local.
     */
    private void enterModule(ExecuteBlock block) {
        String blockModule = block.getModule();
        if (blockModule == null || module != null) {
            return;
        }
        module = blockModule;
        if (variables instanceof ScopedVariables scoped
                && blockModule.equals(scoped.moduleName())) {
            return; // already layered over this module's environment
        }
        Map<String, Object> env = ModuleRegistry.env(blockModule);
        if (env == null) {
            return;
        }
        ScopedVariables layered = new ScopedVariables(env, blockModule);
        for (Map.Entry<String, Object> entry : variables.entrySet()) {
            layered.declareLocal(entry.getKey(), entry.getValue());
        }
        variables = layered;
    }

    /**
     * Execute a single statement, attaching the node's source position to
     * any ScriptError raised below it
     */
    public void execute(Statement statement) {
        if (DebugServer.enabled) {
            DebugServer.trace(statement);
        }
        try {
            statement.execute(this);
        } catch (ScriptError e) {
            if (statement instanceof AbstractAstNode node) {
                throw e.at(node.getLine(), node.getCol());
            }
            throw e;
        }
    }

    /**
     * Evaluate an expression and get its value
     */
    public Object evaluate(Expression expression) {
        return expression.evaluate(this);
    }

    /**
     * Evaluate an expression as a string
     */
    public String evaluateString(Expression expression) {
        Object value = evaluate(expression);
        return NoneValue.isNone(value) ? "" : value.toString();
    }

    /**
     * Evaluate an expression as a boolean
     */
    public boolean evaluateBoolean(Expression expression) {
        Object value = evaluate(expression);
        return Values.toBoolean(value);
    }

    public void emitUi(Statement statement) {
        uiEmitter.emit(statement);
    }

    public Player requirePlayer(Object value, String what) {
        if (value instanceof Player player) {
            return player;
        }
        throw new ScriptError(what + " expects a player, got: " + Values.displayString(value));
    }

    /**
     * Get a variable value with property path resolution through the shared
     * PathResolver; missing roots and hops resolve to none. Dotted paths
     * come from schema v1 and ${...} interpolation.
     */
    public Object getVariable(String path) {
        String[] parts = path.split("\\.");
        Object current = lookupRoot(parts[0]);
        try {
            for (int i = 1; i < parts.length; i++) {
                current = PathResolver.getProperty(current, parts[i], -1, -1);
            }
        } catch (ScriptError e) {
            System.err.println("Warning: " + e.getMessage() + " (in path '" + path + "')");
            return NoneValue.INSTANCE;
        }
        return current;
    }

    private Object lookupRoot(String name) {
        if (variables.containsKey(name)) {
            Object value = variables.get(name);
            return value == null ? NoneValue.INSTANCE : value;
        }
        if (name.equals("args")) {
            // args is a real scope over the argument map
            return variables;
        }
        if (name.equals("server")) {
            // server.tps / server.mspt / server.motd (design 6B/6D)
            return ServerValue.INSTANCE;
        }
        return NoneValue.INSTANCE;
    }

    public PersistStore persistStore() {
        PersistStore store = PersistStore.active();
        if (store == null) {
            throw new ScriptError("persistent variables are not initialized "
                    + "(no storage backend was set up)");
        }
        return store;
    }

    /**
     * Storage key for a keyed persistent access: null subject = global
     * scalar (""); Player subjects key by uuid; a none subject is an error
     */
    public String persistKey(String name, Expression subject) {
        if (subject == null) {
            return "";
        }
        Object value = evaluate(subject);
        if (NoneValue.isNone(value)) {
            throw new ScriptError("subject for persistent '" + name
                    + "' is none - check with `if ... exists` first");
        }
        if (value instanceof Player player) {
            return player.getUuid().toString();
        }
        if (value instanceof net.swofty.players.OfflinePlayerValue offline) {
            // OfflinePlayer subjects key by the same uuid string a Player
            // subject yields, so the two are interchangeable in storage
            return offline.uuid();
        }
        if (value instanceof String key) {
            return key;
        }
        return Values.displayString(value);
    }

    /**
     * Call a function by name - local variables holding a callable first,
     * then user-defined functions (module-local scope first when running
     * inside a module), then builtins
     */
    public Object callFunction(String name, List<Expression> args) {
        if (variables.get(name) instanceof SwoftCallable callable) {
            return callCallable(callable, evaluateCallableArgs(callable, args));
        }
        SwoftFunction function = lookupFunction(name);
        if (function != null) {
            return callUserFunction(function, args);
        }
        return Builtins.call(this, name, args);
    }

    /**
     * Resolve a declared function from this context: the current module's
     * own functions (exported and private) first, then the merged global
     * registry (flat scripts, entry functions, all modules' exports)
     */
    public SwoftFunction lookupFunction(String name) {
        if (module != null) {
            SwoftFunction local = ModuleRegistry.lookup(module, name);
            if (local != null) {
                return local;
            }
        }
        return FunctionRegistry.lookup(name);
    }

    /**
     * Evaluate call-site arguments against a parameter list; missing
     * trailing arguments become none
     */
    public List<Object> evaluateArgs(List<SwoftFunction.Param> params, List<Expression> args) {
        List<Object> values = new ArrayList<>(params.size());
        for (int i = 0; i < params.size(); i++) {
            values.add(i < args.size() ? evaluate(args.get(i)) : NoneValue.INSTANCE);
        }
        return values;
    }

    /**
     * Evaluate call-site arguments for a callable value. The static checker
     * only covers Function-typed callees, so a callable that arrived as Any
     * is checked here: arity must match, and every argument is evaluated.
     */
    public List<Object> evaluateCallableArgs(SwoftCallable callable, List<Expression> args) {
        List<SwoftFunction.Param> params = callable.params();
        if (args.size() != params.size()) {
            throw new ScriptError(callable.displayString() + " expects "
                    + params.size() + " argument(s), got " + args.size());
        }
        List<Object> values = new ArrayList<>(args.size());
        for (Expression arg : args) {
            values.add(evaluate(arg));
        }
        return values;
    }

    /**
     * Call a user-defined function in a child environment
     */
    private Object callUserFunction(SwoftFunction function, List<Expression> args) {
        return callUserFunctionWithValues(function, evaluateArgs(function.params(), args));
    }

    /**
     * Invoke a lambda value: parameters bind in a local layer over the
     * captured environment, everything else reads and writes the captured
     * map itself (closure mutation is visible both ways)
     */
    public Object callCallable(SwoftCallable callable, List<Object> values) {
        if (callable.async() && !AsyncRuntime.inTask()) {
            throw new ScriptError(callable.displayString() + " is an async function; "
                    + "call it with 'spawn ...' or move this call into an async context");
        }
        int depth = callDepth.get();
        if (depth >= MAX_CALL_DEPTH) {
            System.err.println("Error: Function call depth exceeded " + MAX_CALL_DEPTH
                    + " calling: " + callable.displayString());
            return null;
        }

        // preserve the defining scope's module: the invocation env carries
        // it so runBlock's enterModule short-circuits instead of building a
        // fresh layer over the module env (which would swallow writes to
        // captured closure variables in any module bundle)
        ScopedVariables env = new ScopedVariables(callable.captured(), callable.module());
        List<SwoftFunction.Param> params = callable.params();
        for (int i = 0; i < params.size(); i++) {
            env.declareLocal(params.get(i).name(),
                    i < values.size() ? values.get(i) : NoneValue.INSTANCE);
        }

        ASTExecutor childExecutor = new ASTExecutor(sender, env);
        callDepth.set(depth + 1);
        try {
            childExecutor.context().runBlock(callable.body());
            return null;
        } catch (ReturnSignal signal) {
            return signal.getValue();
        } finally {
            callDepth.set(depth);
        }
    }

    /**
     * Invoke a user function with pre-evaluated argument values (used by
     * spawn, which evaluates in the parent before detaching). Functions
     * owned by a module run with their environment layered over the
     * module's variable map, closure-style: module vars read and write
     * through, while sender/event and the bound arguments stay call-local.
     */
    public Object callUserFunctionWithValues(SwoftFunction function, List<Object> values) {
        int depth = callDepth.get();
        if (depth >= MAX_CALL_DEPTH) {
            System.err.println("Error: Function call depth exceeded " + MAX_CALL_DEPTH +
                    " calling: " + function.name());
            return null;
        }

        // Fresh environment: only sender/event carry over, plus bound arguments
        Map<String, Object> moduleEnv =
                function.module() != null ? ModuleRegistry.env(function.module()) : null;
        Map<String, Object> childVariables;
        if (moduleEnv != null) {
            ScopedVariables scoped = new ScopedVariables(moduleEnv, function.module());
            if (variables.containsKey("sender")) {
                scoped.declareLocal("sender", variables.get("sender"));
            }
            if (variables.containsKey("event")) {
                scoped.declareLocal("event", variables.get("event"));
            }
            List<SwoftFunction.Param> params = function.params();
            for (int i = 0; i < params.size(); i++) {
                scoped.declareLocal(params.get(i).name(),
                        i < values.size() ? values.get(i) : NoneValue.INSTANCE);
            }
            childVariables = scoped;
        } else {
            Map<String, Object> plain = new HashMap<>();
            if (variables.containsKey("sender")) {
                plain.put("sender", variables.get("sender"));
            }
            if (variables.containsKey("event")) {
                plain.put("event", variables.get("event"));
            }
            List<SwoftFunction.Param> params = function.params();
            for (int i = 0; i < params.size(); i++) {
                plain.put(params.get(i).name(),
                        i < values.size() ? values.get(i) : NoneValue.INSTANCE);
            }
            childVariables = plain;
        }

        ASTExecutor childExecutor = new ASTExecutor(sender, childVariables);
        childExecutor.context().setModule(function.module());
        callDepth.set(depth + 1);
        try {
            childExecutor.context().runBlock(function.body());
            return null;
        } catch (ReturnSignal signal) {
            return signal.getValue();
        } finally {
            callDepth.set(depth);
        }
    }
}
