package net.swofty.mapper;

import java.util.HashMap;
import java.util.Map;
import java.util.function.BiConsumer;
import java.util.function.Function;

/**
 * Provides custom property mappings for objects
 * This allows overriding the default reflection-based property resolution
 * @param <T> The type of object this mapper handles
 */
public class PropertyMapper<T> {
    private final Class<T> targetClass;
    private final Map<String, Function<T, Object>> getters = new HashMap<>();
    private final Map<String, BiConsumer<T, Object>> setters = new HashMap<>();

    public PropertyMapper(Class<T> targetClass) {
        this.targetClass = targetClass;
    }

    /**
     * Register a custom getter for a property
     * @param propertyName The name of the property
     * @param getter A function that extracts the property value from the target object
     * @return This mapper for chaining
     */
    public PropertyMapper<T> registerGetter(String propertyName, Function<T, Object> getter) {
        getters.put(propertyName.toLowerCase(), getter);
        return this;
    }

    /**
     * Register a custom setter for a property
     * @param propertyName The name of the property
     * @param setter A function that sets the property value on the target object
     * @return This mapper for chaining
     */
    public PropertyMapper<T> registerSetter(String propertyName, BiConsumer<T, Object> setter) {
        setters.put(propertyName.toLowerCase(), setter);
        return this;
    }

    /**
     * Register both a getter and setter for a property
     * @param propertyName The name of the property
     * @param getter A function that extracts the property value from the target object
     * @param setter A function that sets the property value on the target object
     * @return This mapper for chaining
     */
    public PropertyMapper<T> registerProperty(String propertyName,
                                              Function<T, Object> getter,
                                              BiConsumer<T, Object> setter) {
        registerGetter(propertyName, getter);
        registerSetter(propertyName, setter);
        return this;
    }

    /**
     * Check if this mapper has a custom getter for the given property
     * @param propertyName The name of the property
     * @return True if a custom getter is registered
     */
    public boolean hasGetter(String propertyName) {
        return getters.containsKey(propertyName.toLowerCase());
    }

    /**
     * Check if this mapper has a custom setter for the given property
     * @param propertyName The name of the property
     * @return True if a custom setter is registered
     */
    public boolean hasSetter(String propertyName) {
        return setters.containsKey(propertyName.toLowerCase());
    }

    /**
     * Get a property value using the custom getter
     * @param obj The target object
     * @param propertyName The name of the property
     * @return The property value, or null if no getter is registered
     */
    @SuppressWarnings("unchecked")
    public Object getProperty(Object obj, String propertyName) {
        if (!targetClass.isInstance(obj) || !hasGetter(propertyName)) {
            return null;
        }

        T typedObj = (T) obj;
        Function<T, Object> getter = getters.get(propertyName.toLowerCase());
        return getter.apply(typedObj);
    }

    /**
     * Set a property value using the custom setter
     * @param obj The target object
     * @param propertyName The name of the property
     * @param value The value to set
     * @return True if the property was set, false if no setter is registered
     */
    @SuppressWarnings("unchecked")
    public boolean setProperty(Object obj, String propertyName, Object value) {
        if (!targetClass.isInstance(obj) || !hasSetter(propertyName)) {
            return false;
        }

        T typedObj = (T) obj;
        BiConsumer<T, Object> setter = setters.get(propertyName.toLowerCase());
        setter.accept(typedObj, value);
        return true;
    }

    /**
     * Get the target class for this mapper
     */
    public Class<T> getTargetClass() {
        return targetClass;
    }
}