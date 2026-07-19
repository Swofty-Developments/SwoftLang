package net.swofty.props;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;

import net.kyori.adventure.text.Component;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.GameMode;
import net.minestom.server.instance.Instance;
import net.minestom.server.item.ItemStack;
import net.minestom.server.item.Material;
import net.swofty.InstanceRegistry;
import net.swofty.ScriptError;
import net.swofty.TextFormat;

/**
 * Shared coercion table for property writes and value-creating builtins.
 * Failures are ScriptErrors; the executor attaches source positions.
 */
public final class Coercions {
    private Coercions() {
    }

    public static Number requireNumber(Object value, String what) {
        if (value instanceof Number number) {
            return number;
        }
        if (value instanceof String s) {
            try {
                return s.contains(".") ? Double.parseDouble(s) : Long.parseLong(s);
            } catch (NumberFormatException ignored) {
            }
        }
        throw new ScriptError("expected a number for " + what + ", got: " + display(value));
    }

    public static Object toFloat(Object value) {
        return requireNumber(value, "a float property").floatValue();
    }

    public static Object toDouble(Object value) {
        return requireNumber(value, "a double property").doubleValue();
    }

    public static Object toInt(Object value) {
        return requireNumber(value, "an integer property").intValue();
    }

    public static Function<Object, Object> floatClamped(float min, float max, String what) {
        return value -> Math.clamp(requireNumber(value, what).floatValue(), min, max);
    }

    public static Function<Object, Object> doubleAbove(double exclusiveMin, String what) {
        return value -> {
            double d = requireNumber(value, what).doubleValue();
            if (d <= exclusiveMin) {
                throw new ScriptError(what + " must be greater than " + exclusiveMin + ", got: " + d);
            }
            return d;
        };
    }

    public static Function<Object, Object> floatAbove(float exclusiveMin, String what) {
        return value -> {
            float f = requireNumber(value, what).floatValue();
            if (f <= exclusiveMin) {
                throw new ScriptError(what + " must be greater than " + exclusiveMin + ", got: " + f);
            }
            return f;
        };
    }

    public static Function<Object, Object> intClamped(int min, int max, String what) {
        return value -> Math.clamp(requireNumber(value, what).intValue(), min, max);
    }

    public static Function<Object, Object> intAtLeast(int min, String what) {
        return value -> {
            int i = requireNumber(value, what).intValue();
            if (i < min) {
                throw new ScriptError(what + " must be at least " + min + ", got: " + i);
            }
            return i;
        };
    }

    public static Object toItemAmount(Object value) {
        int amount = requireNumber(value, "item amount").intValue();
        if (amount <= 0) {
            throw new ScriptError("item amount must be positive, got: " + amount);
        }
        return Math.min(amount, 99);
    }

    public static Object toHeldSlot(Object value) {
        int slot = requireNumber(value, "held slot").intValue();
        if (slot < 0 || slot > 8) {
            throw new ScriptError("held slot must be 0-8, got: " + slot);
        }
        return (byte) slot;
    }

    public static Object toBoolean(Object value) {
        if (value instanceof Boolean bool) {
            return bool;
        }
        if (value instanceof String s) {
            return Boolean.parseBoolean(s);
        }
        if (value instanceof Number number) {
            return number.doubleValue() != 0;
        }
        throw new ScriptError("expected a boolean, got: " + display(value));
    }

    public static Object toStringValue(Object value) {
        if (NoneValue.isNone(value)) {
            throw new ScriptError("expected a string, got none");
        }
        return value instanceof String s ? s : String.valueOf(value);
    }

    public static Object toGameMode(Object value) {
        if (value instanceof GameMode gameMode) {
            return gameMode;
        }
        if (value instanceof String s) {
            try {
                return GameMode.valueOf(s.toUpperCase());
            } catch (IllegalArgumentException e) {
                throw new ScriptError("unknown gamemode '" + s
                        + "' (valid: survival, creative, adventure, spectator)");
            }
        }
        throw new ScriptError("expected a gamemode, got: " + display(value));
    }

    public static Material toMaterial(Object value) {
        if (value instanceof Material material) {
            return material;
        }
        if (value instanceof String s) {
            String key = s.contains(":") ? s : "minecraft:" + s.toLowerCase();
            Material material = Material.fromKey(key);
            if (material == null) {
                throw new ScriptError("unknown material '" + s + "'");
            }
            return material;
        }
        throw new ScriptError("expected a material, got: " + display(value));
    }

    public static Object toPos(Object value) {
        if (value instanceof Pos pos) {
            return pos;
        }
        throw new ScriptError("expected a location (use the location(x, y, z) builtin), got: "
                + display(value));
    }

    public static Object toVec(Object value) {
        if (value instanceof net.minestom.server.coordinate.Vec vec) {
            return vec;
        }
        if (value instanceof Pos pos) {
            return new net.minestom.server.coordinate.Vec(pos.x(), pos.y(), pos.z());
        }
        throw new ScriptError("expected a vector (use the velocity(x, y, z) builtin), got: "
                + display(value));
    }

    public static Object toItemStack(Object value) {
        if (value instanceof ItemStack itemStack) {
            return itemStack;
        }
        throw new ScriptError("expected an item (use the item(material) builtin), got: "
                + display(value));
    }

    public static Object toComponent(Object value) {
        if (value instanceof Component component) {
            return component;
        }
        return TextFormat.component(String.valueOf(toStringValue(value)));
    }

    public static Object toComponentList(Object value) {
        if (!(value instanceof List<?> list)) {
            throw new ScriptError("expected a list of strings, got: " + display(value));
        }
        List<Component> components = new ArrayList<>(list.size());
        for (Object element : list) {
            components.add((Component) toComponent(element));
        }
        return components;
    }

    public static Object toInstance(Object value) {
        if (value instanceof Instance instance) {
            return instance;
        }
        if (value instanceof String name) {
            Instance instance = InstanceRegistry.get(name);
            if (instance == null) {
                throw new ScriptError("unknown world '" + name + "'");
            }
            return instance;
        }
        throw new ScriptError("expected a world, got: " + display(value));
    }

    private static String display(Object value) {
        if (NoneValue.isNone(value)) {
            return "none";
        }
        return value + " (" + value.getClass().getSimpleName() + ")";
    }
}
