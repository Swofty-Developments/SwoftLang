package net.swofty.maps;

import java.util.HashMap;
import java.util.Map;

/**
 * A tiny embedded 5x7 bitmap font for map-canvas text (design 6D).
 * Glyphs are authored as seven 5-char rows ('X' = pixel). Lowercase
 * letters map to uppercase; unknown characters render a hollow box.
 * Advance is 6 pixels (5 + 1 spacing).
 */
public final class MapFont {
    public static final int WIDTH = 5;
    public static final int HEIGHT = 7;
    public static final int ADVANCE = 6;

    private static final Map<Character, boolean[][]> GLYPHS = new HashMap<>();

    private MapFont() {
    }

    private static void glyph(char c, String... rows) {
        boolean[][] bits = new boolean[HEIGHT][WIDTH];
        for (int y = 0; y < HEIGHT; y++) {
            String row = rows[y];
            for (int x = 0; x < WIDTH && x < row.length(); x++) {
                bits[y][x] = row.charAt(x) == 'X';
            }
        }
        GLYPHS.put(c, bits);
    }

    static {
        glyph(' ', ".....", ".....", ".....", ".....", ".....", ".....", ".....");
        glyph('A', ".XXX.", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X");
        glyph('B', "XXXX.", "X...X", "X...X", "XXXX.", "X...X", "X...X", "XXXX.");
        glyph('C', ".XXX.", "X...X", "X....", "X....", "X....", "X...X", ".XXX.");
        glyph('D', "XXXX.", "X...X", "X...X", "X...X", "X...X", "X...X", "XXXX.");
        glyph('E', "XXXXX", "X....", "X....", "XXXX.", "X....", "X....", "XXXXX");
        glyph('F', "XXXXX", "X....", "X....", "XXXX.", "X....", "X....", "X....");
        glyph('G', ".XXX.", "X...X", "X....", "X.XXX", "X...X", "X...X", ".XXX.");
        glyph('H', "X...X", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X");
        glyph('I', "XXXXX", "..X..", "..X..", "..X..", "..X..", "..X..", "XXXXX");
        glyph('J', "..XXX", "...X.", "...X.", "...X.", "...X.", "X..X.", ".XX..");
        glyph('K', "X...X", "X..X.", "X.X..", "XX...", "X.X..", "X..X.", "X...X");
        glyph('L', "X....", "X....", "X....", "X....", "X....", "X....", "XXXXX");
        glyph('M', "X...X", "XX.XX", "X.X.X", "X.X.X", "X...X", "X...X", "X...X");
        glyph('N', "X...X", "XX..X", "X.X.X", "X..XX", "X...X", "X...X", "X...X");
        glyph('O', ".XXX.", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX.");
        glyph('P', "XXXX.", "X...X", "X...X", "XXXX.", "X....", "X....", "X....");
        glyph('Q', ".XXX.", "X...X", "X...X", "X...X", "X.X.X", "X..X.", ".XX.X");
        glyph('R', "XXXX.", "X...X", "X...X", "XXXX.", "X.X..", "X..X.", "X...X");
        glyph('S', ".XXXX", "X....", "X....", ".XXX.", "....X", "....X", "XXXX.");
        glyph('T', "XXXXX", "..X..", "..X..", "..X..", "..X..", "..X..", "..X..");
        glyph('U', "X...X", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX.");
        glyph('V', "X...X", "X...X", "X...X", "X...X", "X...X", ".X.X.", "..X..");
        glyph('W', "X...X", "X...X", "X...X", "X.X.X", "X.X.X", "XX.XX", "X...X");
        glyph('X', "X...X", "X...X", ".X.X.", "..X..", ".X.X.", "X...X", "X...X");
        glyph('Y', "X...X", "X...X", ".X.X.", "..X..", "..X..", "..X..", "..X..");
        glyph('Z', "XXXXX", "....X", "...X.", "..X..", ".X...", "X....", "XXXXX");
        glyph('0', ".XXX.", "X...X", "X..XX", "X.X.X", "XX..X", "X...X", ".XXX.");
        glyph('1', "..X..", ".XX..", "..X..", "..X..", "..X..", "..X..", "XXXXX");
        glyph('2', ".XXX.", "X...X", "....X", "...X.", "..X..", ".X...", "XXXXX");
        glyph('3', ".XXX.", "X...X", "....X", "..XX.", "....X", "X...X", ".XXX.");
        glyph('4', "...X.", "..XX.", ".X.X.", "X..X.", "XXXXX", "...X.", "...X.");
        glyph('5', "XXXXX", "X....", "XXXX.", "....X", "....X", "X...X", ".XXX.");
        glyph('6', ".XXX.", "X....", "X....", "XXXX.", "X...X", "X...X", ".XXX.");
        glyph('7', "XXXXX", "....X", "...X.", "..X..", ".X...", ".X...", ".X...");
        glyph('8', ".XXX.", "X...X", "X...X", ".XXX.", "X...X", "X...X", ".XXX.");
        glyph('9', ".XXX.", "X...X", "X...X", ".XXXX", "....X", "....X", ".XXX.");
        glyph('.', ".....", ".....", ".....", ".....", ".....", ".XX..", ".XX..");
        glyph(',', ".....", ".....", ".....", ".....", ".XX..", "..X..", ".X...");
        glyph(':', ".....", ".XX..", ".XX..", ".....", ".XX..", ".XX..", ".....");
        glyph(';', ".....", ".XX..", ".XX..", ".....", ".XX..", "..X..", ".X...");
        glyph('!', "..X..", "..X..", "..X..", "..X..", "..X..", ".....", "..X..");
        glyph('?', ".XXX.", "X...X", "....X", "...X.", "..X..", ".....", "..X..");
        glyph('-', ".....", ".....", ".....", "XXXXX", ".....", ".....", ".....");
        glyph('_', ".....", ".....", ".....", ".....", ".....", ".....", "XXXXX");
        glyph('+', ".....", "..X..", "..X..", "XXXXX", "..X..", "..X..", ".....");
        glyph('=', ".....", ".....", "XXXXX", ".....", "XXXXX", ".....", ".....");
        glyph('/', "....X", "....X", "...X.", "..X..", ".X...", "X....", "X....");
        glyph('\\', "X....", "X....", ".X...", "..X..", "...X.", "....X", "....X");
        glyph('(', "...X.", "..X..", ".X...", ".X...", ".X...", "..X..", "...X.");
        glyph(')', ".X...", "..X..", "...X.", "...X.", "...X.", "..X..", ".X...");
        glyph('[', ".XXX.", ".X...", ".X...", ".X...", ".X...", ".X...", ".XXX.");
        glyph(']', ".XXX.", "...X.", "...X.", "...X.", "...X.", "...X.", ".XXX.");
        glyph('\'', "..X..", "..X..", ".....", ".....", ".....", ".....", ".....");
        glyph('"', ".X.X.", ".X.X.", ".....", ".....", ".....", ".....", ".....");
        glyph('#', ".X.X.", ".X.X.", "XXXXX", ".X.X.", "XXXXX", ".X.X.", ".X.X.");
        glyph('%', "XX..X", "XX.X.", "..X..", "..X..", ".X...", "X..XX", "X..XX");
        glyph('*', ".....", ".X.X.", "..X..", "XXXXX", "..X..", ".X.X.", ".....");
        glyph('<', "...X.", "..X..", ".X...", "X....", ".X...", "..X..", "...X.");
        glyph('>', ".X...", "..X..", "...X.", "....X", "...X.", "..X..", ".X...");
        // unknown character: hollow box
        glyph('\0', "XXXXX", "X...X", "X...X", "X...X", "X...X", "X...X", "XXXXX");
    }

    /** Glyph bitmap [row][col]; lowercase folds, unknown = hollow box. */
    public static boolean[][] glyphOf(char c) {
        boolean[][] bits = GLYPHS.get(Character.toUpperCase(c));
        return bits != null ? bits : GLYPHS.get('\0');
    }

    /** Rendered pixel width of a string (no trailing spacing). */
    public static int widthOf(String text) {
        return text.isEmpty() ? 0 : text.length() * ADVANCE - 1;
    }
}
