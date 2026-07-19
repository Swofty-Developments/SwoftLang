package net.swofty.worlds;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Stream;

import net.minestom.server.instance.ChunkLoader;
import net.minestom.server.instance.Instance;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.anvil.AnvilLoader;
import net.swofty.ScriptError;

/**
 * anvil_loader("worlds/") (design 6B): each world is a vanilla anvil
 * directory {@code <dir>/<name>} loaded through Minestom's built-in
 * AnvilLoader.
 */
public final class AnvilWorldLoader implements SwoftWorldLoader {
    private final Path directory;

    public AnvilWorldLoader(String directory) {
        this.directory = Path.of(directory);
    }

    public Path directory() {
        return directory;
    }

    private Path worldPath(String name) {
        WorldsRuntime.validateName(name);
        return directory.resolve(name);
    }

    @Override
    public String kind() {
        return "anvil";
    }

    @Override
    public ChunkLoader chunkLoader(String worldName) {
        Path path = worldPath(worldName);
        try {
            Files.createDirectories(path);
        } catch (IOException e) {
            throw new ScriptError("cannot create anvil world directory " + path
                    + ": " + e.getMessage());
        }
        return new AnvilLoader(path);
    }

    @Override
    public boolean exists(String worldName) {
        Path path = worldPath(worldName);
        return Files.isDirectory(path)
                && (Files.isDirectory(path.resolve("region")) || hasContent(path));
    }

    private static boolean hasContent(Path path) {
        try (Stream<Path> children = Files.list(path)) {
            return children.findAny().isPresent();
        } catch (IOException e) {
            return false;
        }
    }

    @Override
    public List<String> list() {
        if (!Files.isDirectory(directory)) {
            return List.of();
        }
        try (Stream<Path> children = Files.list(directory)) {
            List<String> names = new ArrayList<>();
            children.filter(Files::isDirectory)
                    .map(path -> path.getFileName().toString())
                    .sorted()
                    .forEach(names::add);
            return names;
        } catch (IOException e) {
            throw new ScriptError("cannot list worlds in " + directory + ": " + e.getMessage());
        }
    }

    @Override
    public void save(String worldName, Instance instance) {
        if (instance instanceof InstanceContainer container) {
            container.saveChunksToStorage().join();
        } else {
            throw new ScriptError("world '" + worldName + "' cannot be saved (not a container)");
        }
    }

    @Override
    public void delete(String worldName) {
        deleteRecursively(worldPath(worldName));
    }

    static void deleteRecursively(Path path) {
        if (!Files.exists(path)) {
            return;
        }
        try (Stream<Path> tree = Files.walk(path)) {
            tree.sorted(Comparator.reverseOrder()).forEach(p -> {
                try {
                    Files.delete(p);
                } catch (IOException e) {
                    throw new UncheckedIOException(e);
                }
            });
        } catch (IOException | UncheckedIOException e) {
            throw new ScriptError("cannot delete " + path + ": " + e.getMessage());
        }
    }

    @Override
    public void clone(String from, String to) {
        Path source = worldPath(from);
        Path target = worldPath(to);
        if (!Files.isDirectory(source)) {
            throw new ScriptError("anvil world '" + from + "' does not exist");
        }
        try (Stream<Path> tree = Files.walk(source)) {
            for (Path path : tree.toList()) {
                Path destination = target.resolve(source.relativize(path).toString());
                if (Files.isDirectory(path)) {
                    Files.createDirectories(destination);
                } else {
                    Files.createDirectories(destination.getParent());
                    Files.copy(path, destination,
                            java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                }
            }
        } catch (IOException e) {
            throw new ScriptError("cannot clone world '" + from + "' to '" + to
                    + "': " + e.getMessage());
        }
    }

    @Override
    public void importAnvil(Path anvilDirectory, String worldName) {
        if (!Files.isDirectory(anvilDirectory)) {
            throw new ScriptError("anvil directory " + anvilDirectory + " does not exist");
        }
        Path target = worldPath(worldName);
        try (Stream<Path> tree = Files.walk(anvilDirectory)) {
            for (Path path : tree.toList()) {
                Path destination = target.resolve(anvilDirectory.relativize(path).toString());
                if (Files.isDirectory(path)) {
                    Files.createDirectories(destination);
                } else {
                    Files.createDirectories(destination.getParent());
                    Files.copy(path, destination,
                            java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                }
            }
        } catch (IOException e) {
            throw new ScriptError("cannot import anvil world: " + e.getMessage());
        }
    }

    @Override
    public String toString() {
        return "anvil_loader(" + directory + ")";
    }
}
