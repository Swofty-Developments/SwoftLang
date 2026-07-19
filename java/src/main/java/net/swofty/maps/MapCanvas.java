package net.swofty.maps;

import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

import net.minestom.server.entity.Player;
import net.minestom.server.map.MapColors;
import net.minestom.server.network.packet.server.play.MapDataPacket;
import net.swofty.ScriptError;

/**
 * A 128x128 map framebuffer (design 6D): draw ops mutate the color-id
 * byte array; every mutation pushes a MapDataPacket to the players
 * holding this canvas' map item. Colors resolve through Minestom's
 * MapColors.closestColor (names/hex to the closest base map color id);
 * raw numbers pass through as color-ids.
 */
public final class MapCanvas {
    public static final int SIZE = 128;

    private static final AtomicInteger NEXT_MAP_ID = new AtomicInteger(1_000);

    private final int mapId;
    private final byte[] colors = new byte[SIZE * SIZE];
    private final Set<Player> viewers = ConcurrentHashMap.newKeySet();

    public MapCanvas() {
        this.mapId = NEXT_MAP_ID.getAndIncrement();
    }

    public int mapId() {
        return mapId;
    }

    /** The raw framebuffer (row-major, colors[x + z * 128]). */
    public byte[] colors() {
        return colors;
    }

    public byte get(int x, int y) {
        checkBounds(x, y);
        return colors[x + y * SIZE];
    }

    private static void checkBounds(int x, int y) {
        if (x < 0 || x >= SIZE || y < 0 || y >= SIZE) {
            throw new ScriptError("canvas coordinates out of range (0-127): "
                    + x + ", " + y);
        }
    }

    // ------------------------------------------------------------------
    // draw ops
    // ------------------------------------------------------------------

    public synchronized void setPixel(int x, int y, byte color) {
        checkBounds(x, y);
        colors[x + y * SIZE] = color;
    }

    public synchronized void fillRect(int x, int y, int width, int height, byte color) {
        if (width < 0 || height < 0) {
            throw new ScriptError("canvas rect width/height must be positive, got "
                    + width + "x" + height);
        }
        checkBounds(x, y);
        checkBounds(x + Math.max(0, width - 1), y + Math.max(0, height - 1));
        for (int dy = 0; dy < height; dy++) {
            int base = x + (y + dy) * SIZE;
            for (int dx = 0; dx < width; dx++) {
                colors[base + dx] = color;
            }
        }
    }

    /** Draw text with the embedded 5x7 font; clips at the canvas edge. */
    public synchronized void drawText(int x, int y, String text, byte color) {
        checkBounds(x, y);
        int cursorX = x;
        for (int i = 0; i < text.length(); i++) {
            boolean[][] glyph = MapFont.glyphOf(text.charAt(i));
            for (int gy = 0; gy < MapFont.HEIGHT; gy++) {
                int py = y + gy;
                if (py < 0 || py >= SIZE) {
                    continue;
                }
                for (int gx = 0; gx < MapFont.WIDTH; gx++) {
                    if (!glyph[gy][gx]) {
                        continue;
                    }
                    int px = cursorX + gx;
                    if (px >= 0 && px < SIZE) {
                        colors[px + py * SIZE] = color;
                    }
                }
            }
            cursorX += MapFont.ADVANCE;
            if (cursorX >= SIZE) {
                break;
            }
        }
    }

    // ------------------------------------------------------------------
    // color resolution
    // ------------------------------------------------------------------

    /**
     * A script color value into a map color id byte: numbers are raw
     * ids; "#rrggbb" hex and color names go through
     * MapColors.closestColor.
     */
    public static byte resolveColor(Object value) {
        if (value instanceof Number number) {
            return (byte) number.intValue();
        }
        if (value instanceof String s) {
            Integer rgb = namedRgb(s.toLowerCase());
            if (rgb == null && s.startsWith("#") && s.length() == 7) {
                try {
                    rgb = Integer.parseInt(s.substring(1), 16);
                } catch (NumberFormatException ignored) {
                }
            }
            if (rgb != null) {
                return MapColors.closestColor(rgb).getIndex();
            }
        }
        throw new ScriptError("expected a map color (name, '#rrggbb' or a raw id), got: "
                + value);
    }

    private static Integer namedRgb(String name) {
        return switch (name) {
            case "white" -> 0xFFFFFF;
            case "black" -> 0x000000;
            case "red" -> 0xFF0000;
            case "green" -> 0x00AA00;
            case "lime" -> 0x55FF55;
            case "blue" -> 0x3C44AA;
            case "yellow" -> 0xFFFF55;
            case "orange" -> 0xD87F33;
            case "purple" -> 0xB24CD8;
            case "cyan", "aqua" -> 0x4C7F99;
            case "gray", "grey" -> 0x999999;
            case "brown" -> 0x664C33;
            case "pink" -> 0xF27FA5;
            case "clear", "transparent", "none" -> null; // id 0 via number 0
            default -> null;
        };
    }

    // ------------------------------------------------------------------
    // packets
    // ------------------------------------------------------------------

    /** Full-buffer MapDataPacket for this canvas. */
    public MapDataPacket packet() {
        byte[] snapshot;
        synchronized (this) {
            snapshot = colors.clone();
        }
        return new MapDataPacket(mapId, (byte) 0, true, false, List.of(),
                new MapDataPacket.ColorContent((byte) SIZE, (byte) SIZE,
                        (byte) 0, (byte) 0, snapshot));
    }

    public void addViewer(Player player) {
        viewers.add(player);
        push(player);
    }

    public void push(Player player) {
        try {
            player.sendPacket(packet());
        } catch (Throwable t) {
            // serverless harness: no network
        }
    }

    /** Push the current buffer to every holder (after draw statements). */
    public void pushAll() {
        viewers.removeIf(player -> !player.isOnline());
        for (Player player : viewers) {
            push(player);
        }
    }

    @Override
    public String toString() {
        return "canvas#" + mapId;
    }
}
