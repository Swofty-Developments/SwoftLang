package net.swofty.music;

import net.kyori.adventure.key.Key;
import net.kyori.adventure.sound.Sound;

/**
 * NBS note to Minecraft sound mapping (design 6B): the 16 vanilla NBS
 * instruments onto minecraft:block.note_block.* sound events, plus the
 * classic 25-step note-block pitch table (2^((n-12)/12) for n in 0..24;
 * NBS key 33 = pitch index 0 = F#3).
 */
public final class NoteSounds {
    private static final String[] INSTRUMENT_SOUNDS = {
            "block.note_block.harp",            // 0 piano
            "block.note_block.bass",            // 1 double bass
            "block.note_block.basedrum",        // 2 bass drum
            "block.note_block.snare",           // 3 snare
            "block.note_block.hat",             // 4 click
            "block.note_block.guitar",          // 5 guitar
            "block.note_block.flute",           // 6 flute
            "block.note_block.bell",            // 7 bell
            "block.note_block.chime",           // 8 chime
            "block.note_block.xylophone",       // 9 xylophone
            "block.note_block.iron_xylophone",  // 10 iron xylophone
            "block.note_block.cow_bell",        // 11 cow bell
            "block.note_block.didgeridoo",      // 12 didgeridoo
            "block.note_block.bit",             // 13 bit
            "block.note_block.banjo",           // 14 banjo
            "block.note_block.pling",           // 15 pling
    };

    /** The 25 note-block pitches (index 0-24 -&gt; 0.5 .. 2.0). */
    public static final float[] PITCHES = new float[25];

    static {
        for (int i = 0; i < PITCHES.length; i++) {
            PITCHES[i] = (float) Math.pow(2, (i - 12) / 12.0);
        }
    }

    private NoteSounds() {
    }

    /** Sound event key for an NBS instrument id; custom ids fall to harp. */
    public static Key soundKey(int instrument) {
        String path = instrument >= 0 && instrument < INSTRUMENT_SOUNDS.length
                ? INSTRUMENT_SOUNDS[instrument]
                : INSTRUMENT_SOUNDS[0];
        return Key.key("minecraft", path);
    }

    /** NBS key (0-87) to playback pitch: index = clamp(key - 33, 0, 24). */
    public static float pitch(int nbsKey) {
        int index = Math.clamp(nbsKey - 33, 0, 24);
        return PITCHES[index];
    }

    /** Build the adventure Sound for one note at a volume (0-1). */
    public static Sound sound(NbsSong.Note note, float volume) {
        return Sound.sound(soundKey(note.instrument()), Sound.Source.RECORD,
                volume, pitch(note.key()));
    }

    /** Effective volume 0-1 for a note under a session volume 0-1. */
    public static float noteVolume(NbsSong.Note note, float sessionVolume) {
        return Math.clamp((note.velocity() / 100f) * (note.layerVolume() / 100f)
                * sessionVolume, 0f, 1f);
    }
}
