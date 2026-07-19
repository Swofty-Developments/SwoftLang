package net.swofty;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import net.swofty.compiler.FunctionRegistry;
import net.swofty.compiler.ModuleRegistry;
import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftFunction;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.compiler.SwoftcCompiler;

/**
 * Generic script loader that handles file operations without assuming content type
 */
public class ScriptLoader {
    private final String scriptsDirectory;
    private final String fileExtension;
    private final List<File> scriptFiles = new ArrayList<>();
    private final Map<File, ParsedScript> parseCache = new HashMap<>();

    public ScriptLoader(String scriptsDirectory, String fileExtension) {
        this.scriptsDirectory = scriptsDirectory;
        this.fileExtension = fileExtension;
    }

    /**
     * Scans the scripts directory for files matching the specified extension
     * and compiles each candidate entry. A file that is imported as a module
     * by another scanned script is NOT an entry of its own — compiling it
     * standalone too would register its commands/events twice and leak its
     * private functions into the global registry — so those files are
     * dropped: either up front (their path is already in the
     * ModuleRegistry when their turn comes) or retroactively (they compiled
     * flat first and a later entry's bundle claimed their path).
     * @return List of entry script files found
     */
    public List<File> scanScripts() {
        scriptFiles.clear();
        parseCache.clear();
        FunctionRegistry.clear();
        ModuleRegistry.clear();

        // Ensure the scripts directory exists
        File directory = new File(scriptsDirectory);
        if (!directory.exists()) {
            directory.mkdirs();
            System.out.println("Created scripts directory at: " + directory.getAbsolutePath());
            return scriptFiles;
        }

        List<File> found = new ArrayList<>();
        try {
            // Find all script files in the directory
            try (Stream<Path> paths = Files.walk(Paths.get(scriptsDirectory))) {
                found.addAll(
                    paths.filter(Files::isRegularFile)
                         .filter(path -> path.toString().endsWith("." + fileExtension))
                         .map(Path::toFile)
                         .collect(Collectors.toList())
                );
            }
        } catch (IOException e) {
            System.err.println("Error scanning scripts directory: " + e.getMessage());
            e.printStackTrace();
        }

        for (File file : found) {
            if (loadedAsModule(file)) {
                // an earlier entry's bundle already loaded this file
                System.out.println("Skipping " + file.getName()
                        + ": already loaded as a module of another script");
                continue;
            }
            scriptFiles.add(file);
            try {
                parseScript(file);
            } catch (Exception e) {
                // keep the file listed; processors report per-file errors
            }
        }

        // retroactive pass: a file that compiled flat BEFORE a later entry
        // imported it now exists twice — drop the standalone copy
        for (File file : List.copyOf(scriptFiles)) {
            if (!loadedAsModule(file)) {
                continue;
            }
            System.out.println("Dropping " + file.getName()
                    + ": it is a module of another script, not an entry");
            scriptFiles.remove(file);
            ParsedScript parsed = parseCache.remove(file);
            if (parsed != null) {
                // the flat copy's functions must leave the global registry;
                // the importing bundle re-registered the exported ones
                for (SwoftFunction function : parsed.functions()) {
                    FunctionRegistry.unregister(function);
                }
            }
        }

        return scriptFiles;
    }

    /**
     * True when this file's source path is registered in the ModuleRegistry
     * as a non-entry module — i.e. some scanned script imports it
     */
    private static boolean loadedAsModule(File file) {
        ModuleRegistry.Module module = ModuleRegistry.at(
                file.getAbsoluteFile().toPath().normalize().toString());
        if (module == null) {
            module = ModuleRegistry.at(file.getPath());
        }
        return module != null && !module.entry();
    }

    /**
     * Compiles and loads a script file, caching the result so each file is
     * only compiled once per scan. Functions are registered on first parse.
     * @param file The script file to parse
     * @return The parsed script
     * @throws IOException If the file cannot be compiled or read
     */
    public ParsedScript parseScript(File file) throws IOException, InterruptedException {
        ParsedScript parsed = parseCache.get(file);
        if (parsed == null) {
            // every entry compiles against the shared addons/ search path;
            // modules imported by several entries register once (the loader
            // skips already-loaded module paths)
            String json = SwoftcCompiler.compile(file, sharedAddonPath());
            parsed = SwoftJsonLoader.load(json, relativePath(file));
            parseCache.put(file, parsed);

            for (SwoftFunction function : parsed.functions()) {
                FunctionRegistry.register(function);
                System.out.println("Loaded function: " + function.name() + " from " + file.getName());
            }
        }
        return parsed;
    }

    /**
     * The shared addon search path for bare {@code import "name"} imports:
     * an 'addons' directory next to the scripts directory (for the repo
     * layout, {@code <repo>/addons} beside {@code <repo>/scripts})
     */
    private File sharedAddonPath() {
        File scriptsDir = new File(scriptsDirectory).getAbsoluteFile();
        File parent = scriptsDir.getParentFile();
        return new File(parent != null ? parent : scriptsDir, "addons");
    }

    /** The shared addon search path (public for the hot-reload watcher). */
    public File addonPath() {
        return sharedAddonPath();
    }

    /** Absolute path of the scripts directory, for the debug hello message. */
    public String scriptsDirAbsolute() {
        return new File(scriptsDirectory).getAbsolutePath();
    }

    /**
     * Workspace-relative path of a script file for the debug tracer, e.g.
     * "scripts/chat.sw" — relative to the parent of the scripts directory,
     * with forward slashes. Falls back to the bare file name off-tree.
     */
    public String relativePath(File file) {
        File scriptsDir = new File(scriptsDirectory).getAbsoluteFile();
        File base = scriptsDir.getParentFile();
        try {
            Path relative = (base != null ? base : scriptsDir).toPath()
                    .relativize(file.getAbsoluteFile().toPath());
            String text = relative.toString().replace(File.separatorChar, '/');
            return text.startsWith("..") ? file.getName() : text;
        } catch (RuntimeException e) {
            return file.getName();
        }
    }

    /**
     * Reads a script file's content
     * @param file The script file to read
     * @return The content of the script file as a string
     * @throws IOException If the file cannot be read
     */
    public String readScriptContent(File file) throws IOException {
        return Files.readString(file.toPath());
    }

    /**
     * Returns all currently found script files
     * @return List of script files
     */
    public List<File> getScriptFiles() {
        return scriptFiles;
    }
}
