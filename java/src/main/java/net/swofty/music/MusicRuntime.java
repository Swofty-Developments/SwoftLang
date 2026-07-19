package net.swofty.music;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.entity.Player;
import net.swofty.props.NoneValue;
import net.swofty.props.PropertyDef;
import net.swofty.props.PropertyRegistry;

/**
 * Per-player song sessions (design 6B): at most one active session per
 * player; playing a new song replaces the old session. Also registers
 * the Song value property rows (title/author/description/length/speed/
 * duration).
 */
public final class MusicRuntime {
    private static final Map<UUID, SongSession> SESSIONS = new ConcurrentHashMap<>();

    private MusicRuntime() {
    }

    public static SongSession play(Player player, NbsSong song, int startTick, float volume) {
        stop(player);
        SongSession session = new SongSession(player, song, startTick, volume);
        SESSIONS.put(player.getUuid(), session);
        session.start(() -> SESSIONS.remove(player.getUuid(), session));
        return session;
    }

    public static SongSession sessionOf(Player player) {
        return SESSIONS.get(player.getUuid());
    }

    public static void pause(Player player) {
        SongSession session = sessionOf(player);
        if (session != null) {
            session.pause();
        }
    }

    public static void resume(Player player) {
        SongSession session = sessionOf(player);
        if (session != null) {
            session.resume();
        }
    }

    public static void stop(Player player) {
        SongSession session = SESSIONS.remove(player.getUuid());
        if (session != null) {
            session.stop();
        }
    }

    public static void setVolume(Player player, float volume) {
        SongSession session = sessionOf(player);
        if (session != null) {
            session.setVolume(volume);
        }
    }

    public static void fade(Player player, float target, int durationTicks) {
        SongSession session = sessionOf(player);
        if (session != null) {
            session.fadeTo(target, durationTicks);
        }
    }

    public static void stopAll() {
        SESSIONS.values().forEach(SongSession::stop);
        SESSIONS.clear();
    }

    public static int sessionCount() {
        return SESSIONS.size();
    }

    /** Song value + player song-state property rows (design 6B). */
    public static void registerProperties() {
        PropertyRegistry.register(PropertyDef.readOnly("title", NbsSong.class,
                NbsSong::title));
        PropertyRegistry.register(PropertyDef.readOnly("author", NbsSong.class,
                NbsSong::author));
        PropertyRegistry.register(PropertyDef.readOnly("original_author", NbsSong.class,
                NbsSong::originalAuthor));
        PropertyRegistry.register(PropertyDef.readOnly("description", NbsSong.class,
                NbsSong::description));
        PropertyRegistry.register(PropertyDef.readOnly("length", NbsSong.class,
                NbsSong::lengthTicks));
        PropertyRegistry.register(PropertyDef.readOnly("speed", NbsSong.class,
                NbsSong::tempo));
        PropertyRegistry.register(PropertyDef.readOnly("duration_seconds", NbsSong.class,
                NbsSong::durationSeconds));
        PropertyRegistry.register(PropertyDef.readOnly("note_count", NbsSong.class,
                NbsSong::noteCount));

        // <player>.song: the playing Song (none), <player>.song_tick
        PropertyRegistry.register(PropertyDef.readOnly("song", Player.class,
                player -> {
                    SongSession session = sessionOf(player);
                    return session != null && !session.isStopped()
                            ? session.song() : NoneValue.INSTANCE;
                }));
        PropertyRegistry.register(PropertyDef.readOnly("song_tick", Player.class,
                player -> {
                    SongSession session = sessionOf(player);
                    return session != null ? session.currentTick() : NoneValue.INSTANCE;
                }));
    }
}
