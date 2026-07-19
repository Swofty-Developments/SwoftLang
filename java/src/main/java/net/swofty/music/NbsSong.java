package net.swofty.music;

import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * A parsed .nbs song (design 6B). Notes are grouped per tick in play
 * order; tempo is ticks-per-second (the header short / 100).
 */
public final class NbsSong {

    /** One note block: instrument 0-15 vanilla, key 0-87, effects v4+. */
    public record Note(
            int instrument,
            int key,
            /** 0-100; pre-v4 files default 100. */
            int velocity,
            /** 0-200, 100 = center; pre-v4 default 100. */
            int panning,
            /** fine pitch in cents, 0 = none (v4+). */
            int finePitch,
            /** owning layer volume 0-100 (layer section; default 100). */
            int layerVolume) {
    }

    private final int version;
    private final String title;
    private final String author;
    private final String originalAuthor;
    private final String description;
    /** ticks per second. */
    private final double tempo;
    private final int lengthTicks;
    private final Map<Integer, List<Note>> notesByTick;

    public NbsSong(int version, String title, String author, String originalAuthor,
            String description, double tempo, int lengthTicks,
            Map<Integer, List<Note>> notesByTick) {
        this.version = version;
        this.title = title;
        this.author = author;
        this.originalAuthor = originalAuthor;
        this.description = description;
        this.tempo = tempo;
        this.lengthTicks = lengthTicks;
        this.notesByTick = Collections.unmodifiableMap(notesByTick);
    }

    public int version() {
        return version;
    }

    public String title() {
        return title;
    }

    public String author() {
        return author;
    }

    public String originalAuthor() {
        return originalAuthor;
    }

    public String description() {
        return description;
    }

    /** Ticks per second (NBS tempo / 100). */
    public double tempo() {
        return tempo;
    }

    public int lengthTicks() {
        return lengthTicks;
    }

    public double durationSeconds() {
        return tempo > 0 ? lengthTicks / tempo : 0;
    }

    public Map<Integer, List<Note>> notesByTick() {
        return notesByTick;
    }

    public List<Note> notesAt(int tick) {
        return notesByTick.getOrDefault(tick, List.of());
    }

    public int noteCount() {
        int count = 0;
        for (List<Note> notes : notesByTick.values()) {
            count += notes.size();
        }
        return count;
    }

    @Override
    public String toString() {
        return "song:" + (title == null || title.isEmpty() ? "untitled" : title);
    }
}
