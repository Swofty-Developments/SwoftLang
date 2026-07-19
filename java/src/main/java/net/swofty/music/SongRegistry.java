package net.swofty.music;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import net.swofty.ScriptError;

/**
 * Song cache over the scripts/songs directory (design 6B). Names resolve
 * with or without the .nbs extension; parsed songs are cached until
 * clear() (script reload).
 */
public final class SongRegistry {
    private static final Map<String, NbsSong> CACHE = new ConcurrentHashMap<>();
    private static volatile Path songsDirectory = Path.of("scripts", "songs");

    private SongRegistry() {
    }

    public static void setSongsDirectory(Path directory) {
        songsDirectory = directory;
    }

    public static Path getSongsDirectory() {
        return songsDirectory;
    }

    public static void clear() {
        CACHE.clear();
    }

    /**
     * Load a song by name ("file", "file.nbs" or a scripts/songs-relative
     * path). ScriptError when the file is missing or unparsable.
     */
    public static NbsSong get(String name) {
        return CACHE.computeIfAbsent(name, SongRegistry::load);
    }

    private static NbsSong load(String name) {
        Path candidate = songsDirectory.resolve(name);
        if (!Files.isRegularFile(candidate)) {
            candidate = songsDirectory.resolve(name + ".nbs");
        }
        if (!Files.isRegularFile(candidate)) {
            throw new ScriptError("unknown song '" + name + "' (looked in "
                    + songsDirectory + ")");
        }
        try {
            return NbsParser.parse(candidate);
        } catch (IOException | RuntimeException e) {
            throw new ScriptError("failed to parse song '" + name + "': " + e.getMessage());
        }
    }
}
