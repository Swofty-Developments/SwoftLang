package net.swofty.debug;

import java.io.File;
import java.io.IOException;
import java.nio.file.FileSystems;
import java.nio.file.Path;
import java.nio.file.StandardWatchEventKinds;
import java.nio.file.WatchEvent;
import java.nio.file.WatchKey;
import java.nio.file.WatchService;
import java.util.HashMap;
import java.util.Map;

import net.minestom.server.MinecraftServer;
import net.swofty.ScriptLoader;
import net.swofty.SwoftLangEngine;
import net.swofty.compiler.SwoftcCompiler;

/**
 * Watches the scripts directory (java.nio {@link WatchService} on a daemon
 * thread) and hot-reloads on any {@code .sw} change. On a change it recompiles
 * the file with swoftc and broadcasts a {@code reload} result to the debug
 * tracer — the swoftc error text on failure, {@code ok:true} on success — then
 * applies a tick-safe engine reload so the new handlers run without a restart.
 */
public final class ReloadWatcher {
    /** Coalesce the burst of events an editor save fires for one file. */
    private static final long DEBOUNCE_MILLIS = 150;

    private final SwoftLangEngine engine;
    private final ScriptLoader loader;
    private final Map<String, Long> lastHandled = new HashMap<>();
    private Thread thread;

    public ReloadWatcher(SwoftLangEngine engine) {
        this.engine = engine;
        this.loader = engine.getScriptLoader();
    }

    /** Start the watch thread. No-op if the scripts directory is missing. */
    public void start() {
        File scriptsDir = new File(loader.scriptsDirAbsolute());
        if (!scriptsDir.isDirectory()) {
            System.err.println("[debug] hot reload disabled: no scripts directory at "
                    + scriptsDir);
            return;
        }
        thread = new Thread(() -> watch(scriptsDir.toPath()), "swoft-debug-watch");
        thread.setDaemon(true);
        thread.start();
        System.out.println("[debug] watching " + scriptsDir + " for .sw changes");
    }

    private void watch(Path dir) {
        try (WatchService watchService = FileSystems.getDefault().newWatchService()) {
            dir.register(watchService,
                    StandardWatchEventKinds.ENTRY_MODIFY,
                    StandardWatchEventKinds.ENTRY_CREATE);
            while (true) {
                WatchKey key;
                try {
                    key = watchService.take();
                } catch (InterruptedException e) {
                    return;
                }
                for (WatchEvent<?> event : key.pollEvents()) {
                    Object context = event.context();
                    if (!(context instanceof Path relative)) {
                        continue;
                    }
                    String name = relative.toString();
                    if (name.endsWith(".sw")) {
                        handleChange(dir.resolve(relative).toFile());
                    }
                }
                if (!key.reset()) {
                    return;
                }
            }
        } catch (IOException e) {
            System.err.println("[debug] hot reload watcher stopped: " + e.getMessage());
        }
    }

    private void handleChange(File file) {
        long now = System.currentTimeMillis();
        Long previous = lastHandled.put(file.getPath(), now);
        if (previous != null && now - previous < DEBOUNCE_MILLIS) {
            return;
        }
        String relative = loader.relativePath(file);
        try {
            // recompile to validate + surface the error text; the engine reload
            // recompiles the whole set again but this drives the reload message
            SwoftcCompiler.compile(file, loader.addonPath());
        } catch (IOException | InterruptedException e) {
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            DebugServer.reload(relative, false, e.getMessage());
            return;
        }
        DebugServer.reload(relative, true, null);
        applyReload();
    }

    /** Apply the reload on the tick thread when a server is running. */
    private void applyReload() {
        if (MinecraftServer.process() != null) {
            MinecraftServer.getSchedulerManager().scheduleNextTick(() -> {
                try {
                    engine.reload();
                } catch (RuntimeException e) {
                    System.err.println("[debug] reload failed: " + e.getMessage());
                }
            });
        } else {
            try {
                engine.reload();
            } catch (RuntimeException e) {
                System.err.println("[debug] reload failed: " + e.getMessage());
            }
        }
    }
}
