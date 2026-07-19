package net.swofty.worlds;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.instance.ChunkLoader;
import net.minestom.server.instance.Instance;
import net.minestom.server.instance.InstanceContainer;
import net.swofty.InstanceRegistry;
import net.swofty.ScriptError;
import net.swofty.async.TickDispatch;

/**
 * Script-loaded worlds (design 6B/6D): create/load register an
 * InstanceContainer with the loader's ChunkLoader and the InstanceRegistry
 * (so world("name") resolves), unload evacuates players and unregisters,
 * save/clone/delete/import delegate to the loader value.
 */
public final class WorldsRuntime {
    private record Loaded(InstanceContainer instance, SwoftWorldLoader loader,
            boolean readonly) {
    }

    private static final Map<String, Loaded> WORLDS = new ConcurrentHashMap<>();

    private WorldsRuntime() {
    }

    /** World names become file paths/storage keys: keep them tame. */
    public static void validateName(String name) {
        if (name == null || name.isEmpty() || !name.matches("[A-Za-z0-9_.-]+")) {
            throw new ScriptError("invalid world name '" + name
                    + "' (letters, digits, '_', '-', '.')");
        }
    }

    public static Instance create(String name, SwoftWorldLoader loader, boolean readonly) {
        validateName(name);
        if (WORLDS.containsKey(name) || InstanceRegistry.get(name) != null) {
            throw new ScriptError("world '" + name + "' is already loaded");
        }
        return register(name, loader, readonly);
    }

    public static Instance load(String name, SwoftWorldLoader loader) {
        validateName(name);
        Loaded existing = WORLDS.get(name);
        if (existing != null) {
            return existing.instance();
        }
        if (!loader.exists(name)) {
            throw new ScriptError("world '" + name + "' does not exist in "
                    + loader.kind() + " storage (use create world)");
        }
        return register(name, loader, false);
    }

    private static Instance register(String name, SwoftWorldLoader loader, boolean readonly) {
        ChunkLoader chunkLoader = loader.chunkLoader(name);
        InstanceContainer instance = TickDispatch.call(() ->
                MinecraftServer.getInstanceManager().createInstanceContainer(chunkLoader));
        WORLDS.put(name, new Loaded(instance, loader, readonly));
        InstanceRegistry.register(name, instance);
        return instance;
    }

    public static void unload(String name, boolean save, Pos evacuateTo) {
        Loaded loaded = WORLDS.remove(name);
        if (loaded == null) {
            throw new ScriptError("world '" + name + "' is not loaded");
        }
        try {
            if (save && !loaded.readonly()) {
                loaded.loader().save(name, loaded.instance());
            }
            TickDispatch.call(() -> {
                Instance fallback = InstanceRegistry.get("world");
                // evacuation is only synchronous when the fallback's target
                // chunks are already loaded; otherwise setInstance completes
                // on a later scheduler process, and unregisterInstance
                // throws while any player is still inside. Collect the
                // futures and join them HERE — the pinned future's join()
                // self-processes on the thread that called setInstance, so
                // this cannot deadlock. Kicks are synchronous (online=false)
                List<java.util.concurrent.CompletableFuture<Void>> moves = new ArrayList<>();
                for (Player player : List.copyOf(loaded.instance().getPlayers())) {
                    if (fallback != null && fallback != loaded.instance()) {
                        moves.add(player.setInstance(fallback,
                                evacuateTo != null ? evacuateTo : new Pos(0, 42, 0)));
                    } else {
                        player.kick("world unloaded");
                    }
                }
                for (java.util.concurrent.CompletableFuture<Void> move : moves) {
                    move.join();
                }
                MinecraftServer.getInstanceManager().unregisterInstance(loaded.instance());
                return null;
            });
        } catch (RuntimeException e) {
            // unload failed before the instance was unregistered: restore
            // the entry so the world stays visible and can be retried
            WORLDS.putIfAbsent(name, loaded);
            throw e;
        }
        InstanceRegistry.unregister(name);
    }

    public static void save(String name) {
        Loaded loaded = WORLDS.get(name);
        if (loaded == null) {
            throw new ScriptError("world '" + name + "' is not loaded");
        }
        if (loaded.readonly()) {
            throw new ScriptError("world '" + name + "' was created readonly");
        }
        loaded.loader().save(name, loaded.instance());
    }

    /** The chunk loader an instance was registered with (loaded worlds). */
    public static ChunkLoader chunkLoaderOf(Instance instance) {
        if (instance instanceof InstanceContainer container) {
            return container.getChunkLoader();
        }
        return null;
    }

    public static boolean isLoaded(String name) {
        return WORLDS.containsKey(name);
    }

    public static List<String> loadedNames() {
        return new ArrayList<>(WORLDS.keySet());
    }

    public static void unloadAll() {
        for (String name : List.copyOf(WORLDS.keySet())) {
            try {
                unload(name, false, null);
            } catch (RuntimeException e) {
                System.err.println("[worlds] unload '" + name + "' failed: " + e.getMessage());
            }
        }
    }
}
