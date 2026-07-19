package net.swofty.music;

import net.minestom.server.entity.Player;
import net.swofty.async.AsyncRuntime;
import net.swofty.async.TickClock;

/**
 * One player's song playback (design 6B): a virtual-thread task that
 * advances the song's NBS tick cursor against the server TickClock
 * (fractional server-ticks-per-song-tick accumulate so any tempo stays
 * in time), playing each tick's notes as note-block sounds at the
 * player. Supports pause/resume, stop, live volume, and linear fades.
 */
public final class SongSession {
    private final Player player;
    private final NbsSong song;

    private volatile boolean paused = false;
    private volatile boolean stopped = false;
    private volatile float volume;
    private volatile int currentTick;

    // linear fade state (guarded by this)
    private float fadeFrom;
    private float fadeTo;
    private int fadeTotalTicks;
    private int fadeElapsedTicks;
    private boolean fading;

    SongSession(Player player, NbsSong song, int startTick, float volume) {
        this.player = player;
        this.song = song;
        this.currentTick = Math.max(0, startTick);
        this.volume = Math.clamp(volume, 0f, 1f);
    }

    public Player player() {
        return player;
    }

    public NbsSong song() {
        return song;
    }

    public boolean isPaused() {
        return paused;
    }

    public boolean isStopped() {
        return stopped;
    }

    public int currentTick() {
        return currentTick;
    }

    public float volume() {
        return volume;
    }

    public void pause() {
        paused = true;
    }

    public void resume() {
        paused = false;
    }

    public void stop() {
        stopped = true;
    }

    public synchronized void setVolume(float volume) {
        this.volume = Math.clamp(volume, 0f, 1f);
        this.fading = false;
    }

    /** Linear fade from the current volume to a target over N server ticks. */
    public synchronized void fadeTo(float target, int durationTicks) {
        if (durationTicks <= 0) {
            setVolume(target);
            return;
        }
        fadeFrom = volume;
        fadeTo = Math.clamp(target, 0f, 1f);
        fadeTotalTicks = durationTicks;
        fadeElapsedTicks = 0;
        fading = true;
    }

    private synchronized void advanceFade(int serverTicks) {
        if (!fading) {
            return;
        }
        fadeElapsedTicks += serverTicks;
        if (fadeElapsedTicks >= fadeTotalTicks) {
            volume = fadeTo;
            fading = false;
            return;
        }
        volume = fadeFrom + (fadeTo - fadeFrom) * ((float) fadeElapsedTicks / fadeTotalTicks);
    }

    void start(Runnable onFinished) {
        AsyncRuntime.start("song '" + song.title() + "' for " + player.getUsername(), () -> {
            try {
                run();
            } finally {
                onFinished.run();
            }
        });
    }

    private void run() {
        double tempo = song.tempo() > 0 ? song.tempo() : 10.0;
        double serverTicksPerSongTick = 20.0 / tempo;
        double carried = 0;
        while (!stopped) {
            if (paused) {
                sleepTicks(2);
                continue;
            }
            if (currentTick >= song.lengthTicks()) {
                return; // finished
            }
            if (!player.isOnline()) {
                stopped = true;
                return;
            }

            for (NbsSong.Note note : song.notesAt(currentTick)) {
                float noteVolume = NoteSounds.noteVolume(note, volume);
                if (noteVolume <= 0f) {
                    continue;
                }
                player.playSound(NoteSounds.sound(note, noteVolume));
            }
            currentTick++;

            carried += serverTicksPerSongTick;
            int wait = (int) carried;
            carried -= wait;
            if (wait > 0) {
                sleepTicks(wait);
                advanceFade(wait);
            }
        }
    }

    private void sleepTicks(int ticks) {
        try {
            TickClock.after(ticks).get();
        } catch (Exception e) {
            Thread.currentThread().interrupt();
            stopped = true;
        }
    }
}
