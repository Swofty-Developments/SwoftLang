package net.swofty;

import java.io.File;
import java.util.List;

import net.swofty.processors.CommandProcessor;
import net.swofty.processors.EventProcessor;

/**
 * Main entry point for the SwoftLang scripting engine
 * Coordinates script loading and processing
 */
public class SwoftLangEngine {
    private final ScriptLoader scriptLoader;
    private final CommandProcessor commandProcessor;
    private final EventProcessor eventProcessor;

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
        this.eventProcessor = new EventProcessor(scriptLoader);
    }

    /**
     * Initialize the engine by scanning and processing all scripts
     */
    public void initialize() {
        System.out.println("Initializing SwoftLang Engine...");

        // Scan for script files
        List<File> files = scriptLoader.scanScripts();
        System.out.println("Found " + files.size() + " script files");

       // Process commands
       int commandCount = commandProcessor.processCommands();
       System.out.println("Processed " + commandCount + " commands");
       
       // Process events
       int eventCount = eventProcessor.processEvents();
       System.out.println("Processed " + eventCount + " events");
    }

    /**
     * Register all components with their respective systems
     */
    public void register() {
        // Register commands
        commandProcessor.register();

        // Register events
        eventProcessor.registerEvents();
    }

    /**
     * Get the command processor
     */
    public CommandProcessor getCommandProcessor() {
        return commandProcessor;
    }

    public EventProcessor getEventProcessor() {
        return eventProcessor;
    }
    
    /**
     * Get the script loader
     */
    public ScriptLoader getScriptLoader() {
        return scriptLoader;
    }
}
