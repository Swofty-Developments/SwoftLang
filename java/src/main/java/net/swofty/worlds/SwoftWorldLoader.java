package net.swofty.worlds;

import java.util.List;

import net.minestom.server.instance.ChunkLoader;
import net.minestom.server.instance.Instance;

/**
 * A world storage backend value (design 6B/6D): anvil directories, polar
 * files, or polar blobs inside a SwoftStorage backend. Loader values are
 * created by the anvil_loader/polar_loader/polar_storage_loader builtins
 * and passed to the world statements.
 */
public interface SwoftWorldLoader {

    /** files | polar | polar_storage — used in messages. */
    String kind();

    /** Chunk loader for a world (must exist, or creating one). */
    ChunkLoader chunkLoader(String worldName);

    boolean exists(String worldName);

    List<String> list();

    /** Persist the instance's chunks into this backend under the name. */
    void save(String worldName, Instance instance);

    void delete(String worldName);

    /** Duplicate a stored world without loading it. */
    void clone(String from, String to);

    /** Convert a vanilla anvil directory into this backend under the name. */
    void importAnvil(java.nio.file.Path anvilDirectory, String worldName);
}
