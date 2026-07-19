package net.swofty.displays;

import java.util.List;

import net.minestom.server.coordinate.Pos;
import net.minestom.server.coordinate.Vec;
import net.minestom.server.item.ItemStack;
import net.swofty.ScriptError;
import net.swofty.props.Coercions;
import net.swofty.props.PropertyDef;
import net.swofty.props.PropertyRegistry;
import net.swofty.props.ThreadPolicy;

import static net.swofty.props.ThreadPolicy.ANY;

/**
 * The Display value property namespace (design 6B): text/item/block,
 * scale, translation, rotation (euler degrees), billboard, glow_color,
 * background, alignment, line_width, see_through, view_range, shadow,
 * location, entity_id. Metadata writes are packet-level and thread-safe;
 * location goes through the entity teleport (tick).
 */
public final class DisplayProperties {
    private static boolean registered = false;

    private DisplayProperties() {
    }

    public static synchronized void ensureRegistered() {
        if (registered) {
            return;
        }
        registered = true;

        PropertyRegistry.register(PropertyDef.of("text", SwoftDisplay.class,
                SwoftDisplay::getText,
                (display, value) -> display.setText((String) value),
                null, Coercions::toStringValue, ANY));
        PropertyRegistry.register(PropertyDef.of("item", SwoftDisplay.class,
                SwoftDisplay::getItem,
                (display, value) -> display.setItem((ItemStack) value),
                null, Coercions::toItemStack, ANY));
        PropertyRegistry.register(PropertyDef.of("block", SwoftDisplay.class,
                SwoftDisplay::getBlock,
                (display, value) -> display.setBlock((String) value),
                null, Coercions::toStringValue, ANY));

        PropertyRegistry.register(PropertyDef.of("scale", SwoftDisplay.class,
                SwoftDisplay::getScale,
                (display, value) -> display.setScale((Vec) value),
                null, DisplayProperties::toVec, ANY));
        PropertyRegistry.register(PropertyDef.of("translation", SwoftDisplay.class,
                SwoftDisplay::getTranslation,
                (display, value) -> display.setTranslation((Vec) value),
                null, DisplayProperties::toVec, ANY));
        PropertyRegistry.register(PropertyDef.of("rotation", SwoftDisplay.class,
                SwoftDisplay::getRotationEuler,
                (display, value) -> {
                    Vec euler = (Vec) value;
                    display.setRotationEuler(euler.x(), euler.y(), euler.z());
                },
                null, DisplayProperties::toVec, ANY));

        PropertyRegistry.register(PropertyDef.of("billboard", SwoftDisplay.class,
                SwoftDisplay::getBillboard,
                (display, value) -> display.setBillboard((String) value),
                null, Coercions::toStringValue, ANY));
        PropertyRegistry.register(PropertyDef.of("glow_color", SwoftDisplay.class,
                SwoftDisplay::getGlowColor,
                (display, value) -> display.setGlowColor((Integer) value),
                null, DisplayProperties::toArgb, ANY));
        PropertyRegistry.register(PropertyDef.of("background", SwoftDisplay.class,
                SwoftDisplay::getBackground,
                (display, value) -> display.setBackground((Integer) value),
                null, DisplayProperties::toArgb, ANY));
        PropertyRegistry.register(PropertyDef.of("alignment", SwoftDisplay.class,
                SwoftDisplay::getAlignment,
                (display, value) -> display.setAlignment((String) value),
                null, Coercions::toStringValue, ANY));
        PropertyRegistry.register(PropertyDef.of("line_width", SwoftDisplay.class,
                SwoftDisplay::getLineWidth,
                (display, value) -> display.setLineWidth((Integer) value),
                null, Coercions::toInt, ANY));
        PropertyRegistry.register(PropertyDef.of("see_through", SwoftDisplay.class,
                SwoftDisplay::isSeeThrough,
                (display, value) -> display.setSeeThrough((Boolean) value),
                null, Coercions::toBoolean, ANY));
        PropertyRegistry.register(PropertyDef.of("view_range", SwoftDisplay.class,
                SwoftDisplay::getViewRange,
                (display, value) -> display.setViewRange((Float) value),
                null, Coercions::toFloat, ANY));
        PropertyRegistry.register(PropertyDef.of("shadow_radius", SwoftDisplay.class,
                SwoftDisplay::getShadowRadius,
                (display, value) -> display.setShadowRadius((Float) value),
                null, Coercions::toFloat, ANY));

        PropertyRegistry.register(PropertyDef.of("location", SwoftDisplay.class,
                display -> display.entity().getPosition(),
                (display, value) -> display.teleport((Pos) value),
                null, Coercions::toPos, ThreadPolicy.TICK));
        PropertyRegistry.register(PropertyDef.readOnly("entity_id", SwoftDisplay.class,
                display -> display.entity().getEntityId()));
        PropertyRegistry.register(PropertyDef.readOnly("uuid", SwoftDisplay.class,
                display -> display.entity().getUuid().toString()));
        PropertyRegistry.register(PropertyDef.readOnly("kind", SwoftDisplay.class,
                display -> display.kind().name().toLowerCase()));
    }

    /** [x, y, z] list, a Vec, or a location coerce into a Vec. */
    static Object toVec(Object value) {
        if (value instanceof Vec vec) {
            return vec;
        }
        if (value instanceof Pos pos) {
            return new Vec(pos.x(), pos.y(), pos.z());
        }
        if (value instanceof List<?> list && list.size() == 3
                && list.get(0) instanceof Number x
                && list.get(1) instanceof Number y
                && list.get(2) instanceof Number z) {
            return new Vec(x.doubleValue(), y.doubleValue(), z.doubleValue());
        }
        if (value instanceof Number n) {
            // uniform scale shorthand
            double d = n.doubleValue();
            return new Vec(d, d, d);
        }
        throw new ScriptError("expected [x, y, z] (or a single number) for this "
                + "display property, got: " + value);
    }

    /**
     * ARGB color: an integer, "#rrggbb" / "#aarrggbb" hex, or a small set
     * of color names. Alpha defaults to opaque.
     */
    static Object toArgb(Object value) {
        if (value instanceof Number number) {
            return number.intValue();
        }
        if (value instanceof String s) {
            String hex = s.startsWith("#") ? s.substring(1) : null;
            if (hex != null && (hex.length() == 6 || hex.length() == 8)) {
                try {
                    long parsed = Long.parseLong(hex, 16);
                    if (hex.length() == 6) {
                        parsed |= 0xFF000000L;
                    }
                    return (int) parsed;
                } catch (NumberFormatException ignored) {
                }
            }
            Integer named = namedColor(s.toLowerCase());
            if (named != null) {
                return named;
            }
        }
        throw new ScriptError("expected a color (integer, '#rrggbb' or a color name), got: "
                + value);
    }

    private static Integer namedColor(String name) {
        return switch (name) {
            case "white" -> 0xFFFFFFFF;
            case "black" -> 0xFF000000;
            case "red" -> 0xFFFF5555;
            case "green" -> 0xFF55FF55;
            case "blue" -> 0xFF5555FF;
            case "yellow" -> 0xFFFFFF55;
            case "gold", "orange" -> 0xFFFFAA00;
            case "aqua", "cyan" -> 0xFF55FFFF;
            case "purple", "magenta" -> 0xFFAA00AA;
            case "gray", "grey" -> 0xFFAAAAAA;
            case "dark_gray", "dark_grey" -> 0xFF555555;
            case "pink" -> 0xFFFF55FF;
            case "transparent", "none" -> 0x00000000;
            default -> null;
        };
    }
}
