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
     * Process all script files and extract commands
     * @return Number of commands processed
     */
    public int processCommands() {
        commandMap.clear();
        List<File> scriptFiles = scriptLoader.getScriptFiles();
        
        int totalCommands = 0;
        
        for (File scriptFile : scriptFiles) {
            try {
                String scriptContent = scriptLoader.readScriptContent(scriptFile);
                Command[] commands = net.swofty.nativebridge.NativeParser.parseSwoftLangToCommands(scriptContent);
                
                if (commands != null) {
                    for (Command command : commands) {
                        // Store the command in the map, using name as the key
                        commandMap.put(command.getName(), command);
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