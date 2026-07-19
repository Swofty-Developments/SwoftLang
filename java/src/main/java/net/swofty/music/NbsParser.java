package net.swofty.music;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * Note Block Studio .nbs parser, written from scratch against the NBS
 * format spec, versions 0 (classic) through 5 (design 6B). All values
 * little-endian. Layout:
 *
 * <pre>
 * header:
 *   v0:  short songLength
 *   v1+: short 0 (new-format marker), byte version, byte vanillaInstrumentCount
 *   v3+: short songLength (returned to the header)
 *   short layerCount
 *   string songName, string author, string originalAuthor, string description
 *   short tempo (t/s * 100)
 *   byte autoSaving, byte autoSavingDuration, byte timeSignature
 *   int minutesSpent, int leftClicks, int rightClicks, int blocksAdded,
 *   int blocksRemoved, string importFileName
 *   v4+: byte loop, byte maxLoopCount, short loopStartTick
 * notes (jump-encoded):
 *   loop: short tickJump (0 = end); per tick loop: short layerJump (0 = next
 *   tick); note: byte instrument, byte key, v4+: byte velocity,
 *   ubyte panning, short finePitch
 * layers (optional trailer):
 *   per layer: string name, v4+: byte locked, byte volume, v2+: ubyte stereo
 * </pre>
 *
 * The layer trailer, when present, back-fills each note's layer volume.
 */
public final class NbsParser {

    private NbsParser() {
    }

    public static NbsSong parse(Path file) throws IOException {
        return parse(Files.readAllBytes(file));
    }

    public static NbsSong parse(byte[] bytes) {
        ByteBuffer buffer = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN);

        // --- header ---
        int version = 0;
        int songLength = Short.toUnsignedInt(buffer.getShort());
        if (songLength == 0) {
            version = Byte.toUnsignedInt(buffer.get());
            if (version > 5) {
                throw new IllegalArgumentException(
                        "unsupported NBS version " + version + " (this parser reads 0-5)");
            }
            buffer.get(); // vanilla instrument count
            if (version >= 3) {
                songLength = Short.toUnsignedInt(buffer.getShort());
            }
        }
        int layerCount = Short.toUnsignedInt(buffer.getShort());
        String title = readString(buffer);
        String author = readString(buffer);
        String originalAuthor = readString(buffer);
        String description = readString(buffer);
        double tempo = Short.toUnsignedInt(buffer.getShort()) / 100.0;
        buffer.get();       // auto-saving
        buffer.get();       // auto-saving duration
        buffer.get();       // time signature
        buffer.getInt();    // minutes spent
        buffer.getInt();    // left clicks
        buffer.getInt();    // right clicks
        buffer.getInt();    // note blocks added
        buffer.getInt();    // note blocks removed
        readString(buffer); // import file name
        if (version >= 4) {
            buffer.get();       // loop on/off
            buffer.get();       // max loop count
            buffer.getShort();  // loop start tick
        }

        // --- note blocks (jump encoding) ---
        record RawNote(int tick, int layer, int instrument, int key,
                int velocity, int panning, int finePitch) {
        }
        List<RawNote> rawNotes = new ArrayList<>();
        int tick = -1;
        int maxTick = 0;
        while (buffer.remaining() >= 2) {
            int tickJump = Short.toUnsignedInt(buffer.getShort());
            if (tickJump == 0) {
                break;
            }
            tick += tickJump;
            int layer = -1;
            while (buffer.remaining() >= 2) {
                int layerJump = Short.toUnsignedInt(buffer.getShort());
                if (layerJump == 0) {
                    break;
                }
                layer += layerJump;
                int instrument = Byte.toUnsignedInt(buffer.get());
                int key = Byte.toUnsignedInt(buffer.get());
                int velocity = 100;
                int panning = 100;
                int finePitch = 0;
                if (version >= 4) {
                    velocity = Byte.toUnsignedInt(buffer.get());
                    panning = Byte.toUnsignedInt(buffer.get());
                    finePitch = buffer.getShort();
                }
                rawNotes.add(new RawNote(tick, layer, instrument, key,
                        velocity, panning, finePitch));
            }
            maxTick = Math.max(maxTick, tick);
        }

        // --- optional layer trailer: name, [locked], volume, [stereo] ---
        Map<Integer, Integer> layerVolumes = new HashMap<>();
        try {
            for (int i = 0; i < layerCount && buffer.remaining() > 0; i++) {
                readString(buffer); // layer name
                if (version >= 4) {
                    buffer.get(); // locked
                }
                int volume = Byte.toUnsignedInt(buffer.get());
                layerVolumes.put(i, volume);
                if (version >= 2) {
                    buffer.get(); // stereo
                }
            }
        } catch (RuntimeException truncated) {
            // truncated/absent layer section: volumes default to 100
            layerVolumes.clear();
        }

        Map<Integer, List<NbsSong.Note>> notesByTick = new TreeMap<>();
        for (RawNote raw : rawNotes) {
            int layerVolume = layerVolumes.getOrDefault(raw.layer(), 100);
            notesByTick.computeIfAbsent(raw.tick(), t -> new ArrayList<>())
                    .add(new NbsSong.Note(raw.instrument(), raw.key(), raw.velocity(),
                            raw.panning(), raw.finePitch(), layerVolume));
        }

        int length = songLength > 0 ? songLength : maxTick + 1;
        return new NbsSong(version, title, author, originalAuthor, description,
                tempo, length, notesByTick);
    }

    /** NBS string: int32 length + bytes (Windows-1252 in practice). */
    private static String readString(ByteBuffer buffer) {
        int length = buffer.getInt();
        if (length < 0 || length > buffer.remaining()) {
            throw new IllegalArgumentException("corrupt NBS string (length " + length
                    + ", remaining " + buffer.remaining() + ")");
        }
        byte[] bytes = new byte[length];
        buffer.get(bytes);
        return new String(bytes, StandardCharsets.ISO_8859_1);
    }
}
