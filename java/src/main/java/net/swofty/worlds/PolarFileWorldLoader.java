package net.swofty.worlds;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

import net.hollowcube.polar.AnvilPolar;
import net.hollowcube.polar.PolarLoader;
import net.hollowcube.polar.PolarWorld;
import net.hollowcube.polar.PolarWriter;
import net.minestom.server.instance.ChunkLoader;
import net.minestom.server.instance.Instance;
import net.swofty.ScriptError;

/**
 * polar_loader("worlds/") (design 6B): each world is one
 * {@code <dir>/<name>.polar} file, read and written through
 * dev.hollowcube:polar.
 */
public final class PolarFileWorldLoader implements SwoftWorldLoader {
    private final Path directory;

    public PolarFileWorldLoader(String directory) {
        this.directory = Path.of(directory);
    }

    private Path worldPath(String name) {
        WorldsRuntime.validateName(name);
        return directory.resolve(name + ".polar");
    }

    @Override
    public String kind() {
        return "polar";
    }

    @Override
    public ChunkLoader chunkLoader(String worldName) {
        Path path = worldPath(worldName);
        try {
            Files.createDirectories(directory);
            if (Files.isRegularFile(path)) {
                return new PolarLoader(path);
            }
            // new world: an empty polar world that saves back to the path
            return new PolarLoader(path, new PolarWorld());
        } catch (IOException e) {
            throw new ScriptError("cannot open polar world " + path + ": " + e.getMessage());
        }
    }

    @Override
    public boolean exists(String worldName) {
        return Files.isRegularFile(worldPath(worldName));
    }

    @Override
    public List<String> list() {
        if (!Files.isDirectory(directory)) {
            return List.of();
        }
        try (Stream<Path> children = Files.list(directory)) {
            List<String> names = new ArrayList<>();
            children.filter(Files::isRegularFile)
                    .map(path -> path.getFileName().toString())
                    .filter(name -> name.endsWith(".polar"))
                    .map(name -> name.substring(0, name.length() - ".polar".length()))
                    .sorted()
                    .forEach(names::add);
            return names;
        } catch (IOException e) {
            throw new ScriptError("cannot list polar worlds in " + directory
                    + ": " + e.getMessage());
        }
    }

    @Override
    public void save(String worldName, Instance instance) {
        ChunkLoader loader = WorldsRuntime.chunkLoaderOf(instance);
        if (loader == null) {
            throw new ScriptError("world '" + worldName + "' has no chunk loader to save with");
        }
        loader.saveInstance(instance);
        loader.saveChunks(instance.getChunks());
    }

    @Override
    public void delete(String worldName) {
        try {
            Files.deleteIfExists(worldPath(worldName));
        } catch (IOException e) {
            throw new ScriptError("cannot delete polar world '" + worldName
                    + "': " + e.getMessage());
        }
    }

    @Override
    public void clone(String from, String to) {
        Path source = worldPath(from);
        if (!Files.isRegularFile(source)) {
            throw new ScriptError("polar world '" + from + "' does not exist");
        }
        try {
            Files.createDirectories(directory);
            Files.copy(source, worldPath(to), StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new ScriptError("cannot clone polar world '" + from + "' to '" + to
                    + "': " + e.getMessage());
        }
    }

    @Override
    public void importAnvil(Path anvilDirectory, String worldName) {
        try {
            PolarWorld world = AnvilPolar.anvilToPolar(anvilDirectory);
            Files.createDirectories(directory);
            Files.write(worldPath(worldName), PolarWriter.write(world));
        } catch (IOException e) {
            throw new ScriptError("cannot import anvil world " + anvilDirectory
                    + ": " + e.getMessage());
        }
    }

    @Override
    public String toString() {
        return "polar_loader(" + directory + ")";
    }
}
