package net.swofty.mapper;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Registry for property mappers that provides custom property resolution
 */
public class PropertyMapperRegistry {
    private static final Map<Class<?>, PropertyMapper<?>> mappers = new HashMap<>();
    private static final List<PropertyMapper<?>> wildcardMappers = new ArrayList<>();

    /**
     * Register a property mapper
     * @param mapper The mapper to register
     */
    public static <T> void registerMapper(PropertyMapper<T> mapper) {
        mappers.put(mapper.getTargetClass(), mapper);
    }

    /**
     * Register a wildcard mapper that will be checked for any class
     * These are checked after specific class mappers
     * @param mapper The wildcard mapper to register
     */
    public static <T> void registerWildcardMapper(PropertyMapper<T> mapper) {
        wildcardMappers.add(mapper);
    }

    /**
     * Try to get a property value using registered mappers
     * @param obj The target object
     * @param propertyName The name of the property
     * @return The property value, or null if no mapper can handle it
     */
    @SuppressWarnings("unchecked")
    public static Object getProperty(Object obj, String propertyName) {
        if (obj == null) {
            return null;
        }

        // Try exact class mapper
        PropertyMapper<?> mapper = mappers.get(obj.getClass());
        if (mapper != null && mapper.hasGetter(propertyName)) {
            return mapper.getProperty(obj, propertyName);
        }

        // Try superclass mappers
        Class<?> currentClass = obj.getClass().getSuperclass();
        while (currentClass != null) {
            mapper = mappers.get(currentClass);
            if (mapper != null && mapper.hasGetter(propertyName)) {
                return mapper.getProperty(obj, propertyName);
            }
            currentClass = currentClass.getSuperclass();
        }

        // Try interface mappers
        for (Class<?> iface : obj.getClass().getInterfaces()) {
            mapper = mappers.get(iface);
            if (mapper != null && mapper.hasGetter(propertyName)) {
                return mapper.getProperty(obj, propertyName);
            }
        }

        // Try wildcard mappers
        for (PropertyMapper<?> wildcardMapper : wildcardMappers) {
            if (wildcardMapper.getTargetClass().isInstance(obj) &&
                    wildcardMapper.hasGetter(propertyName)) {
                return wildcardMapper.getProperty(obj, propertyName);
            }
        }

        // No mapper found
        return null;
    }

    /**
     * Try to set a property value using registered mappers
     * @param obj The target object
     * @param propertyName The name of the property
     * @param value The value to set
     * @return True if the property was set, false if no mapper can handle it
     */
    @SuppressWarnings("unchecked")
    public static boolean setProperty(Object obj, String propertyName, Object value) {
        if (obj == null) {
            return false;
        }

        // Try exact class mapper
        PropertyMapper<?> mapper = mappers.get(obj.getClass());
        if (mapper != null && mapper.hasSetter(propertyName)) {
            return mapper.setProperty(obj, propertyName, value);
        }

        // Try superclass mappers
        Class<?> currentClass = obj.getClass().getSuperclass();
        while (currentClass != null) {
            mapper = mappers.get(currentClass);
            if (mapper != null && mapper.hasSetter(propertyName)) {
                return mapper.setProperty(obj, propertyName, value);
            }
            currentClass = currentClass.getSuperclass();
        }

        // Try interface mappers
        for (Class<?> iface : obj.getClass().getInterfaces()) {
            mapper = mappers.get(iface);
            if (mapper != null && mapper.hasSetter(propertyName)) {
                return mapper.setProperty(obj, propertyName, value);
            }
        }

        // Try wildcard mappers
        for (PropertyMapper<?> wildcardMapper : wildcardMappers) {
            if (wildcardMapper.getTargetClass().isInstance(obj) &&
                    wildcardMapper.hasSetter(propertyName)) {
                return wildcardMapper.setProperty(obj, propertyName, value);
            }
        }

        // No mapper found
        return false;
    }
}