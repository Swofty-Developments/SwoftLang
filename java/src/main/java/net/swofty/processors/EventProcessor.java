package net.swofty.processors;

import net.swofty.ScriptLoader;
import net.swofty.nativebridge.NativeParser;
import net.swofty.nativebridge.representation.Event;
import net.swofty.event.EventRegistrar;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class EventProcessor {
    private final ScriptLoader scriptLoader;
    private final List<Event> events = new ArrayList<>();
    private final EventRegistrar eventRegistrar;

    public EventProcessor(ScriptLoader scriptLoader) {
        this.scriptLoader = scriptLoader;
        this.eventRegistrar = new EventRegistrar();
    }

    public int processEvents() {
        events.clear();
        List<File> scriptFiles = scriptLoader.getScriptFiles();
        
        int totalEvents = 0;
        
        for (File scriptFile : scriptFiles) {
            try {
                String scriptContent = scriptLoader.readScriptContent(scriptFile);
                Event[] parsedEvents = NativeParser.parseSwoftLangToEvents(scriptContent);
                
                if (parsedEvents != null) {
                    for (Event event : parsedEvents) {
                        if (event != null) {
                            events.add(event);
                            System.out.println("Loaded event: " + event.getName() + " from " + scriptFile.getName());
                            totalEvents++;
                        }
                    }
                }
            } catch (Exception e) {
                System.err.println("Error parsing script file: " + scriptFile.getName());
                e.printStackTrace();
            }
        }
        
        System.out.println("Total events processed: " + events.size());
        return events.size();
    }

    public void registerEvents() {
        // Sort events by priority (lower numbers = higher priority)
        events.sort((e1, e2) -> Integer.compare(e1.getPriority(), e2.getPriority()));
        
        // Register each event with the event system
        for (Event event : events) {
            eventRegistrar.registerEvent(event);
        }
    }

    public List<Event> getEvents() {
        return new ArrayList<>(events);
    }
}