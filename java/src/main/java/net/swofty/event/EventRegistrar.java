package net.swofty.event;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.MinecraftServer;
import net.minestom.server.event.EventListener;
import net.minestom.server.event.EventNode;
import net.swofty.nativebridge.representation.Event;
public class EventRegistrar {
    private final EventNode<net.minestom.server.event.Event> rootNode;
    private final Map<String, EventNode<?>> eventNodes = new ConcurrentHashMap<>();

    public EventRegistrar() {
        this.rootNode = MinecraftServer.getGlobalEventHandler();
    }

    @SuppressWarnings("unchecked")
    public void registerEvent(Event event) {
        String eventName = event.getName();

        // Find the EventType for this event name
        EventType eventType = EventType.fromIdentifier(eventName);
        if (eventType == null) {
            System.err.println("Unknown event type: " + eventName);
            return;
        }

        // Get the Minestom class name for this event
        String minestomClassName = EventType.getMinestomClassName(eventName);
        
        // Get or create event node for this event type
        EventNode<?> node = eventNodes.computeIfAbsent(eventName, name -> {
            try {
                // Load the Minestom event class
                Class<?> minestomEventClass = Class.forName(minestomClassName);
                System.out.println("Found Minestom event class: " + minestomEventClass.getName());
                
                // Create a node for this event type
                EventNode<net.minestom.server.event.Event> eventNode = EventNode.all("swoftlang-" + name);
                rootNode.addChild(eventNode);
                return eventNode;
            } catch (ClassNotFoundException e) {
                System.err.println("Could not find Minestom event class: " + minestomClassName);
                e.printStackTrace();
                return null;
            }
        });


        if (node == null) return;

        try {
            // Load the Minestom event class
            Class<net.minestom.server.event.Event> eventClass = 
                (Class<net.minestom.server.event.Event>) Class.forName(minestomClassName);
                
            // Create the listener
            EventListener<net.minestom.server.event.Event> listener = 
                EventListener.of(eventClass, minestomEvent -> {
                    // Use the event type factory to create the appropriate wrapper
                    AbstractSwoftEvent<?> wrapper = eventType.getFactory().create(minestomEvent, event);
                    
                    // Execute the SwoftLang event handler
                    wrapper.execute();
                });
                
            // Register the listener
            ((EventNode<net.minestom.server.event.Event>) node).addListener(listener);
            System.out.println("Successfully registered listener for event: " + eventName);
        } catch (ClassNotFoundException e) {
            System.err.println("Failed to create listener for event: " + eventName);
            e.printStackTrace();
        }
    }

    private Class<? extends net.minestom.server.event.Event> getEventClass(String eventName) {
        try {
            String className = eventName.startsWith("Player") ?
                    "net.minestom.server.event.player." + eventName :
                    "net.minestom.server.event.entity." + eventName;

            return (Class<? extends net.minestom.server.event.Event>) Class.forName(className);
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("Event class not found: " + eventName, e);
        }
    }
}