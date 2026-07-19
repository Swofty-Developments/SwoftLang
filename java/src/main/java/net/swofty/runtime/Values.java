package net.swofty.runtime;

import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.instance.Instance;
import net.minestom.server.item.ItemStack;
import net.swofty.InstanceRegistry;
import net.swofty.props.NoneValue;

/**
 * Value-level semantics shared by the runtime: truthiness, equality,
 * comparison, type checks and display formatting.
 */
public final class Values {
    private Values() {
    }

    public static String displayString(Object value) {
        if (value instanceof Player) {
            return ((Player) value).getUsername();
        } else if (value instanceof net.swofty.players.OfflinePlayerValue offline) {
            return offline.name();
        } else if (value instanceof Pos) {
            Pos loc = (Pos) value;
            return String.format("x=%.1f, y=%.1f, z=%.1f", loc.x(), loc.y(), loc.z());
        } else if (value instanceof net.minestom.server.coordinate.Vec vec) {
            return String.format("x=%.2f, y=%.2f, z=%.2f", vec.x(), vec.y(), vec.z());
        } else if (value instanceof net.swofty.mobs.SwoftMob mob) {
            return mob.toString();
        } else if (value instanceof net.minestom.server.entity.Entity entity) {
            return entity.getEntityType().key().asString() + "#" + entity.getEntityId();
        } else if (value instanceof ItemStack) {
            ItemStack item = (ItemStack) value;
            return item.material().name() + " x" + item.amount();
        } else if (value instanceof Instance) {
            return InstanceRegistry.nameOf((Instance) value);
        } else if (value instanceof SwoftCallable) {
            return ((SwoftCallable) value).displayString();
        } else if (value instanceof net.minestom.server.entity.PlayerSkin) {
            return "skin";
        } else if (value instanceof MapValue) {
            return value.toString();
        } else if (value == NoneValue.INSTANCE) {
            return "none";
        } else if (value != null) {
            return value.toString();
        } else {
            return "null";
        }
    }

    /**
     * Convert an object to a boolean
     */
    public static boolean toBoolean(Object obj) {
        if (obj instanceof Boolean) {
            return (Boolean) obj;
        }
        if (obj instanceof Number) {
            return ((Number) obj).doubleValue() != 0;
        }
        if (obj instanceof String) {
            return !((String) obj).isEmpty();
        }
        return !NoneValue.isNone(obj);
    }

    /**
     * Check if two objects are equal. Numeric-aware THROUGH collections: two
     * lists are equal iff order-sensitively element-equal by this same rule
     * ({@code [1] == [1.0]}, {@code [1,2] != [2,1]}); two maps are equal iff
     * they have the same key set and order-insensitively value-equal by this
     * rule ({@code {a:1} == {a:1.0}}). Nested collections recurse. Values are
     * acyclic, so no cycle guard is needed.
     */
    public static boolean objectsEqual(Object left, Object right) {
        if (NoneValue.isNone(left) && NoneValue.isNone(right)) return true;
        if (NoneValue.isNone(left) || NoneValue.isNone(right)) return false;

        // Handle numeric comparison
        if (left instanceof Number && right instanceof Number) {
            return ((Number) left).doubleValue() == ((Number) right).doubleValue();
        }

        // Lists compare order-sensitively, element-wise through objectsEqual so
        // numeric coercion (1 == 1.0) reaches inside the collection.
        if (left instanceof java.util.List<?> leftList
                && right instanceof java.util.List<?> rightList) {
            if (leftList.size() != rightList.size()) {
                return false;
            }
            for (int i = 0; i < leftList.size(); i++) {
                if (!objectsEqual(leftList.get(i), rightList.get(i))) {
                    return false;
                }
            }
            return true;
        }

        // Maps compare order-insensitively: same key set, and each value equal
        // through objectsEqual. Keys use Java equality (String/Integer), values
        // recurse so nested maps/lists and 1 == 1.0 both hold.
        if (left instanceof java.util.Map<?, ?> leftMap
                && right instanceof java.util.Map<?, ?> rightMap) {
            if (leftMap.size() != rightMap.size()) {
                return false;
            }
            for (java.util.Map.Entry<?, ?> entry : leftMap.entrySet()) {
                if (!rightMap.containsKey(entry.getKey())
                        || !objectsEqual(entry.getValue(), rightMap.get(entry.getKey()))) {
                    return false;
                }
            }
            return true;
        }

        return left.equals(right);
    }

    /**
     * Compare two objects
     */
    public static int compareObjects(Object left, Object right) {
        if (left instanceof Number && right instanceof Number) {
            double l = ((Number) left).doubleValue();
            double r = ((Number) right).doubleValue();
            return Double.compare(l, r);
        }

        if (left instanceof String && right instanceof String) {
            return ((String) left).compareTo((String) right);
        }

        throw new RuntimeException("Cannot compare objects of types: " +
                (left != null ? left.getClass().getSimpleName() : "null") + " and " +
                (right != null ? right.getClass().getSimpleName() : "null"));
    }

    /**
     * Check if an object is of a certain type
     */
    public static boolean isType(Object obj, String typeName) {
        // Must cover every name the checker accepts (typecheck.ml known_type_names)
        switch (typeName) {
            case "Player":
                return obj instanceof Player;
            case "OfflinePlayer":
                // Player <: OfflinePlayer - 'is a OfflinePlayer' holds for
                // both live players and pure-offline identities
                return obj instanceof net.swofty.players.OfflinePlayerValue
                        || obj instanceof Player;
            case "Location":
                return obj instanceof Pos;
            case "String":
                return obj instanceof String;
            case "Number":
                return obj instanceof Number;
            case "Integer":
            case "Int":
            case "int":
                return obj instanceof Integer || obj instanceof Long;
            case "Double":
            case "double":
                return obj instanceof Double || obj instanceof Float;
            case "Boolean":
            case "Bool":
            case "bool":
                return obj instanceof Boolean;
            case "World":
                return obj instanceof Instance;
            case "Item":
                return obj instanceof ItemStack;
            case "Mob":
                return obj instanceof net.swofty.mobs.SwoftMob;
            case "Entity":
                // every Minestom entity (mobs included: SwoftMob IS an
                // EntityCreature, so 'is a Entity' holds for mobs)
                return obj instanceof net.minestom.server.entity.Entity;
            case "Projectile":
                return obj instanceof net.minestom.server.entity.EntityProjectile;
            case "Vec":
            case "Vector":
            case "Velocity":
                return obj instanceof net.minestom.server.coordinate.Vec;
            case "Display":
                return obj instanceof net.swofty.displays.SwoftDisplay;
            case "Song":
                return obj instanceof net.swofty.music.NbsSong;
            case "Skin":
                return obj instanceof net.minestom.server.entity.PlayerSkin;
            case "Canvas":
                return obj instanceof net.swofty.maps.MapCanvas;
            case "Schedule":
                return obj instanceof net.swofty.sched.ScheduleHandle;
            case "Request":
                return obj instanceof net.swofty.http.SwoftHttpRequest;
            case "WorldLoader":
            case "Loader":
                return obj instanceof net.swofty.worlds.SwoftWorldLoader;
            case "Map":
                return obj instanceof MapValue;
            default:
                return false;
        }
    }

    /**
     * Coerce a script value to a map key. Keys are String OR Integer, one type
     * per map (the checker enforces K). An Integer key is preserved as a boxed
     * {@link Integer} (a whole Long narrows to Integer) so it addresses an
     * Integer-keyed row by value equality; a String key stays a String. A
     * {@link Player} (or offline identity) key hashes by its uuid STRING so a
     * {@code map<Player, V>} is reconnect-stable: the same account addresses
     * the same row across a disconnect/reconnect (the runtime Player object
     * changes, the uuid does not). Any other scalar (Double, Boolean) falls
     * back to its string form — no cross-type coercion between key kinds.
     */
    public static Object coerceMapKey(Object value) {
        if (value instanceof Integer) {
            return value;
        }
        if (value instanceof Long l) {
            return (int) (long) l;
        }
        if (value instanceof String) {
            return value;
        }
        if (value instanceof Player player) {
            return player.getUuid().toString();
        }
        if (value instanceof net.swofty.players.OfflinePlayerValue offline) {
            return offline.uuid();
        }
        return net.swofty.props.Coercions.toStringValue(value);
    }

    /**
     * Format color codes in a string
     */
    public static String formatColorCodes(String text) {
        return text.replace("<red>", "§c")
                .replace("<green>", "§a")
                .replace("<lime>", "§a")
                .replace("<blue>", "§9")
                .replace("<yellow>", "§e")
                .replace("<gold>", "§6")
                .replace("<white>", "§f")
                .replace("<black>", "§0")
                .replace("<reset>", "§r");
    }
}
