package net.swofty.processors;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.swofty.ScriptLoader;
import net.swofty.command.MinestomCommandRegistrar;
import net.swofty.nativebridge.representation.Command;

public class CommandProcessor {
    private final ScriptLoader scriptLoader;
    private final Map<String, Command> commandMap = new HashMap<>();

    public CommandProcessor(ScriptLoader scriptLoader) {
        this.scriptLoader = scriptLoader;
    }

    /**
     * Process all script files and extract commands. Colliding names (a
     * later script or imported addon declaring an already-taken command or
     * alias) log an error naming both sources instead of silently
     * last-winning. The first registration is kept, with one fail-closed
     * exception: a permission-guarded declaration always beats an
     * unguarded one, so scan order can never leave a guarded command
     * shadowed by an open handler.
     * @return Number of commands processed
     */
    public int processCommands() {
        commandMap.clear();
        Map<String, File> provenance = new HashMap<>();
        List<File> scriptFiles = scriptLoader.getScriptFiles();

        int totalCommands = 0;

        for (File scriptFile : scriptFiles) {
            try {
                for (Command command : scriptLoader.parseScript(scriptFile).commands()) {
                    if (command != null) {
                        Command existing = commandMap.get(command.getName());
                        if (existing != null) {
                            File first = provenance.get(command.getName());
                            boolean preferIncoming = isGuarded(command) && !isGuarded(existing);
                            System.err.println("Error: duplicate command '" + command.getName()
                                    + "': declared in both "
                                    + (first != null ? first.getName() : "an earlier script")
                                    + " and " + scriptFile.getName() + " - keeping the "
                                    + (preferIncoming
                                            ? "permission-guarded declaration from "
                                                    + scriptFile.getName()
                                            : "first"));
                            if (!preferIncoming) {
                                continue;
                            }
                        }
                        // Store the command in the map, using name as the key
                        commandMap.put(command.getName(), command);
                        provenance.put(command.getName(), scriptFile);
                        System.out.println("Loaded command: " + command.getName() + " from " + scriptFile.getName());
                        totalCommands++;
                    }
                }
            } catch (Exception e) {
                System.err.println("Error parsing script file: " + scriptFile.getName());
                e.printStackTrace();
            }
        }

        System.out.println("Total commands processed: " + totalCommands);
        return commandMap.size();
    }

    private static boolean isGuarded(Command command) {
        return command.getPermission() != null && !command.getPermission().isEmpty();
    }

    /**
     * Get all commands
     * @return List of all commands
     */
    public List<Command> getCommands() {
        return new ArrayList<>(commandMap.values());
    }

    /**
     * Get a specific command by name
     * @param name Command name
     * @return The command, or null if not found
     */
    public Command getCommand(String name) {
        return commandMap.get(name);
    }

    /**
     * Get the internal command map
     * @return Map of command name to Command object
     */
    public Map<String, Command> getCommandMap() {
        return commandMap;
    }

    /**
     * Register all commands with the Minestom command system
     */
    public void register() {
        // Create the registrar
        MinestomCommandRegistrar registrar = new MinestomCommandRegistrar();

        // Register all commands
        registrar.registerCommands(commandMap);
    }
}