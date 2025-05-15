package net.swofty.mapper;

import java.util.function.BiConsumer;
import java.util.function.Function;

/**
 * Base interface for property mappers
 * Each implementation will handle a specific class or group of classes
 */
public interface PropertyMapperProvider {
    
    /**
     * Initialize this mapper and register all mappings
     */
    void registerMappings();
    
    /**
     * Helper method to create and register a property mapper
     */
    default <T> void registerMapper(Class<T> targetClass, 
                                    String propertyName, 
                                    Function<T, Object> getter, 
                                    BiConsumer<T, Object> setter) {
        PropertyMapper<T> mapper = new PropertyMapper<>(targetClass);
        mapper.registerProperty(propertyName, getter, setter);
        PropertyMapperRegistry.registerMapper(mapper);
    }
}