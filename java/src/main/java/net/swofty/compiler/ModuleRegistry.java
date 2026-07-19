package net.swofty.compiler;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import net.swofty.ASTExecutor;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.runtime.ScopedVariables;
import net.swofty.runtime.SystemSender;

/**
 * Runtime registry of loaded modules (design 6A). Each module owns a
 * variable environment (its module-level {@code var} declarations, shared
 * closure-style by every call into the module) and the full set of its
 * functions, private ones included. Exported symbols additionally land in
 * the merged global registries with per-symbol provenance so collisions can
 * name both offending modules.
 *
 * <p>Modules are identified by their source path: a module imported by
 * several entry scripts registers once, on first load.
 */
public final class ModuleRegistry {

    /** One module-level 'var name = expr' declaration, evaluated at load. */
    public record VarDecl(String name, Expression initializer) {
    }

    public static final class Module {
        private final String name;
        private final String path;
        private final boolean entry;
        /**
         * The live module variable environment. Concurrent so async tasks
         * mutating module vars in parallel (api handlers, every-schedules,
         * async blocks) never corrupt the map or read stale entries. Note
         * that compound updates ({@code set hits to hits + 1}) are still a
         * read-then-write and are NOT atomic across concurrent tasks.
         */
        private final Map<String, Object> vars = new ConcurrentHashMap<>();
        private final Map<String, SwoftFunction> functions = new HashMap<>();
        private final List<VarDecl> varDecls = new ArrayList<>();
        private boolean initialized;

        private Module(String name, String path, boolean entry) {
            this.name = name;
            this.path = path;
            this.entry = entry;
        }

        public String name() {
            return name;
        }

        public String path() {
            return path;
        }

        public boolean entry() {
            return entry;
        }

        /** The live module variable environment. */
        public Map<String, Object> vars() {
            return vars;
        }

        public void addFunction(SwoftFunction function) {
            functions.put(function.name(), function);
        }

        public void addVarDecl(VarDecl decl) {
            varDecls.add(decl);
        }
    }

    private static final Map<String, Module> byName = new LinkedHashMap<>();
    private static final Map<String, String> loadedPaths = new HashMap<>();
    // "kind:id" -> provenance description of the module that claimed it
    private static final Map<String, String> symbols = new HashMap<>();

    private ModuleRegistry() {
    }

    /** Has the module at this source path already been registered? */
    public static boolean isLoaded(String path) {
        return loadedPaths.containsKey(path);
    }

    /** The module registered at this source path, or null. */
    public static Module at(String path) {
        String name = loadedPaths.get(path);
        return name != null ? byName.get(name) : null;
    }

    /**
     * Validate that {@link #register} would succeed, without committing —
     * bundle loads stage all their checks before registering anything so a
     * collision never leaves a half-registered module behind
     */
    public static void checkRegisterable(String name, String path) {
        Module existing = byName.get(name);
        if (existing != null && !existing.path.equals(path)) {
            throw new IllegalStateException("two modules with the same name '" + name
                    + "': " + existing.path + " and " + path);
        }
    }

    public static Module register(String name, String path, boolean entry) {
        checkRegisterable(name, path);
        Module existing = byName.get(name);
        Module module = existing != null ? existing : new Module(name, path, entry);
        byName.put(name, module);
        loadedPaths.put(path, name);
        return module;
    }

    private static String where(String name, String path) {
        return "module '" + name + "' (" + path + ")";
    }

    /**
     * Claim a globally-registered symbol (exported function, item id, mob
     * id, gui/scoreboard/tablist/bossbar name, persistent name) for
     * collision detection with per-symbol provenance
     */
    public static void claimSymbol(String kind, String id, Module owner) {
        String key = kind + ":" + id;
        String where = where(owner.name, owner.path);
        String previous = symbols.putIfAbsent(key, where);
        if (previous != null && !previous.equals(where)) {
            throw new IllegalStateException("duplicate " + kind + " '" + id
                    + "': declared in both " + previous + " and " + where);
        }
    }

    /**
     * Validate that {@link #claimSymbol} would succeed for this module,
     * without committing the claim (atomic bundle loads stage their checks
     * first)
     */
    public static void checkSymbol(String kind, String id, String name, String path) {
        String previous = symbols.get(kind + ":" + id);
        String where = where(name, path);
        if (previous != null && !previous.equals(where)) {
            throw new IllegalStateException("duplicate " + kind + " '" + id
                    + "': declared in both " + previous + " and " + where);
        }
    }

    /** The module's variable environment, or null if the module is unknown. */
    public static Map<String, Object> env(String module) {
        Module m = byName.get(module);
        return m != null ? m.vars : null;
    }

    /**
     * Resolve a function inside a module's own scope (exported and private
     * alike); null when the module or the name is unknown
     */
    public static SwoftFunction lookup(String module, String name) {
        Module m = byName.get(module);
        return m != null ? m.functions.get(name) : null;
    }

    /**
     * Evaluate the module's var initializers in declaration order. Called
     * once per module after its bundle finished registering (its imports,
     * loaded earlier in dependency order, are already initialized).
     */
    public static void initialize(Module module) {
        if (module.initialized) {
            return;
        }
        module.initialized = true;
        for (VarDecl decl : module.varDecls) {
            // earlier vars of the same module are visible to later initializers
            ScopedVariables env = new ScopedVariables(module.vars, module.name);
            ASTExecutor executor = new ASTExecutor(SystemSender.INSTANCE, env);
            executor.context().setModule(module.name);
            Object value = executor.context().evaluate(decl.initializer());
            // the concurrent vars map rejects nulls; a valueless initializer
            // (void function result) reads back as none either way
            module.vars.put(decl.name(),
                    value != null ? value : net.swofty.props.NoneValue.INSTANCE);
        }
    }

    public static void clear() {
        byName.clear();
        loadedPaths.clear();
        symbols.clear();
    }
}
