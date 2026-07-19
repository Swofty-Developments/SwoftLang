package net.swofty.worlds;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import com.google.gson.JsonElement;
import com.google.gson.JsonPrimitive;

import net.hollowcube.polar.AnvilPolar;
import net.hollowcube.polar.PolarLoader;
import net.hollowcube.polar.PolarReader;
import net.hollowcube.polar.PolarWorld;
import net.hollowcube.polar.PolarWriter;
import net.minestom.server.instance.Chunk;
import net.minestom.server.instance.ChunkLoader;
import net.minestom.server.instance.Instance;
import net.swofty.ScriptError;
import net.swofty.model.StorageBackendModel;
import net.swofty.persist.PersistStore;
import net.swofty.persist.SwoftStorage;

/**
 * polar_storage_loader({...}) (design 6B): polar world bytes as base64
 * blobs inside a phase-3 SwoftStorage backend (files/sqlite/mysql/
 * mongodb), keyed by world name under the reserved variable
 * {@code swoft:worlds}. The same backend config syntax as storage{}.
 */
public final class PolarStorageWorldLoader implements SwoftWorldLoader {
    /** Reserved persistent "variable" holding all world blobs. */
    static final String WORLDS_VAR = "swoft_worlds";

    /**
     * One live backend per config: scripts evaluate the loader
     * expression freely without opening a new connection every time.
     */
    private static final java.util.Map<StorageBackendModel, PolarStorageWorldLoader> CACHE =
            new java.util.concurrent.ConcurrentHashMap<>();

    private final StorageBackendModel backendModel;
    private final SwoftStorage storage;

    public static PolarStorageWorldLoader of(StorageBackendModel backendModel) {
        return CACHE.computeIfAbsent(backendModel, PolarStorageWorldLoader::new);
    }

    private PolarStorageWorldLoader(StorageBackendModel backendModel) {
        this.backendModel = backendModel;
        try {
            this.storage = PersistStore.createBackend(backendModel);
        } catch (RuntimeException e) {
            throw new ScriptError("polar_storage_loader: cannot open backend '"
                    + backendModel.kind() + "': " + e.getMessage());
        }
    }

    @Override
    public String kind() {
        return "polar_storage";
    }

    private Map<String, JsonElement> loadAll() {
        return storage.loadAll(WORLDS_VAR);
    }

    private byte[] loadBlob(String worldName) {
        JsonElement stored = loadAll().get(worldName);
        if (stored == null || stored.isJsonNull()) {
            return null;
        }
        return Base64.getDecoder().decode(stored.getAsString());
    }

    private void storeBlob(String worldName, byte[] bytes) {
        storage.writeBatch(WORLDS_VAR, Map.of(worldName,
                new JsonPrimitive(Base64.getEncoder().encodeToString(bytes))));
    }

    private void removeBlob(String worldName) {
        // JsonNull rows are treated as absent by loadBlob; backends keep
        // the row but the world reads as deleted
        storage.writeBatch(WORLDS_VAR, Map.of(worldName,
                com.google.gson.JsonNull.INSTANCE));
    }

    @Override
    public ChunkLoader chunkLoader(String worldName) {
        WorldsRuntime.validateName(worldName);
        byte[] blob = loadBlob(worldName);
        PolarWorld world = blob != null ? PolarReader.read(blob) : new PolarWorld();
        return new StorageChunkLoader(new PolarLoader(world), worldName);
    }

    /**
     * Wraps the in-memory PolarLoader so every chunk save also pushes the
     * serialized world blob back into the storage backend.
     */
    private final class StorageChunkLoader implements ChunkLoader {
        private final PolarLoader delegate;
        private final String worldName;

        private StorageChunkLoader(PolarLoader delegate, String worldName) {
            this.delegate = delegate;
            this.worldName = worldName;
        }

        @Override
        public void loadInstance(Instance instance) {
            delegate.loadInstance(instance);
        }

        @Override
        public Chunk loadChunk(Instance instance, int chunkX, int chunkZ) {
            return delegate.loadChunk(instance, chunkX, chunkZ);
        }

        @Override
        public void saveInstance(Instance instance) {
            delegate.saveInstance(instance);
            persist();
        }

        @Override
        public void saveChunk(Chunk chunk) {
            delegate.saveChunk(chunk);
            persist();
        }

        @Override
        public void saveChunks(Collection<Chunk> chunks) {
            delegate.saveChunks(chunks);
            persist();
        }

        @Override
        public void unloadChunk(Chunk chunk) {
            delegate.unloadChunk(chunk);
        }

        @Override
        public boolean supportsParallelLoading() {
            return delegate.supportsParallelLoading();
        }

        @Override
        public boolean supportsParallelSaving() {
            // serialize blob writes: one at a time
            return false;
        }

        private synchronized void persist() {
            storeBlob(worldName, PolarWriter.write(delegate.world()));
        }
    }

    @Override
    public boolean exists(String worldName) {
        return loadBlob(worldName) != null;
    }

    @Override
    public List<String> list() {
        List<String> names = new ArrayList<>();
        for (Map.Entry<String, JsonElement> entry : loadAll().entrySet()) {
            if (!entry.getValue().isJsonNull()) {
                names.add(entry.getKey());
            }
        }
        names.sort(String::compareTo);
        return names;
    }

    @Override
    public void save(String worldName, Instance instance) {
        ChunkLoader loader = WorldsRuntime.chunkLoaderOf(instance);
        if (loader == null) {
            throw new ScriptError("world '" + worldName + "' has no chunk loader to save with");
        }
        loader.saveChunks(instance.getChunks());
        loader.saveInstance(instance);
    }

    @Override
    public void delete(String worldName) {
        removeBlob(worldName);
    }

    @Override
    public void clone(String from, String to) {
        byte[] blob = loadBlob(from);
        if (blob == null) {
            throw new ScriptError("stored world '" + from + "' does not exist");
        }
        storeBlob(to, blob);
    }

    @Override
    public void importAnvil(Path anvilDirectory, String worldName) {
        try {
            PolarWorld world = AnvilPolar.anvilToPolar(anvilDirectory);
            storeBlob(worldName, PolarWriter.write(world));
        } catch (java.io.IOException e) {
            throw new ScriptError("cannot import anvil world " + anvilDirectory
                    + ": " + e.getMessage());
        }
    }

    /** Release the backend (script reload). */
    public void close() {
        CACHE.remove(backendModel, this);
        storage.close();
    }

    @Override
    public String toString() {
        return "polar_storage_loader(" + backendModel.kind() + ")";
    }
}
