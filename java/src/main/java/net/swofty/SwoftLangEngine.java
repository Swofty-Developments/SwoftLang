package net.swofty;

import java.io.File;
import java.util.List;

import net.swofty.processors.CommandProcessor;

/**
 * Main entry point for the SwoftLang scripting engine
 * Coordinates script loading and processing
 */
public class SwoftLangEngine {
    private final ScriptLoader scriptLoader;
    private final CommandProcessor commandProcessor;

    /**
     * Initialize the SwoftLang engine with default settings
     */
    public SwoftLangEngine() {
        this("scripts", "sw");
    }

    /**
     * Initialize the SwoftLang engine with custom settings
     * @param scriptsDirectory Directory to search for script files
     * @param fileExtension File extension for script files
     */
    public SwoftLangEngine(String scriptsDirectory, String fileExtension) {
        this.scriptLoader = new ScriptLoader(scriptsDirectory, fileExtension);
        this.commandProcessor = new CommandProcessor(scriptLoader);
    }

    /**
     * Initialize the engine by scanning and processing all scripts
     */
    public void initialize() {
        System.out.println("Initializing SwoftLang Engine...");

        // Scan for script files
        List<File> files = scriptLoader.scanScripts();
        System.out.println("Found " + files.size() + " script files");

        // Process components
        int commandCount = commandProcessor.processCommands();
        System.out.println("Processed " + commandCount + " commands");
    }

    /**
     * Register all components with their respective systems
     */
    public void register() {
        // Register commands
        commandProcessor.register();

        // Additional registration methods for other components can be called here
    }

    /**
     * Get the command processor
     */
    public CommandProcessor getCommandProcessor() {
        return commandProcessor;
    }

    /**
     * Get the script loader
     */
    public ScriptLoader getScriptLoader() {
        return scriptLoader;
    }
}
