package net.swofty.mapper;

import java.util.ArrayList;
import java.util.List;

import net.swofty.mapper.providers.PlayerChatEventMapper;

/**
 * Initializes all property mappers
 */
public class PropertyMapperInitializer {
    // List of all mapper providers to initialize
    private static final List<PropertyMapperProvider> MAPPERS = new ArrayList<>();
    
    // Flag to track if initialization has been done
    private static boolean initialized = false;
    
    /**
     * Initialize all property mappers
     * This should be called once at startup
     */
    public static void initialize() {
        if (initialized) {
            return;
        }
        
        // Register all mapper providers
        registerMapperProviders();
        
        // Initialize each mapper provider
        for (PropertyMapperProvider provider : MAPPERS) {
            provider.registerMappings();
        }
        
        initialized = true;
        System.out.println("Initialized " + MAPPERS.size() + " property mappers");
    }
    
    /**
     * Register all mapper providers
     * Add new mapper providers here
     */
    private static void registerMapperProviders() {
        // Manual registration of mapper providers
        MAPPERS.add(new PlayerChatEventMapper());
    }
    
    /**
     * Check if mappers have been initialized
     */
    public static boolean isInitialized() {
        return initialized;
    }
}