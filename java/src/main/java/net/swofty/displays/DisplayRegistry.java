package net.swofty.displays;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Live display entities spawned by scripts, so reloads/shutdowns can
 * clean up every script-owned display in one sweep.
 */
public final class DisplayRegistry {
    private static final Set<SwoftDisplay> DISPLAYS = ConcurrentHashMap.newKeySet();

    private DisplayRegistry() {
    }

    static void track(SwoftDisplay display) {
        DISPLAYS.add(display);
    }

    static void untrack(SwoftDisplay display) {
        DISPLAYS.remove(display);
    }

    public static int count() {
        return DISPLAYS.size();
    }

    public static void destroyAll() {
        for (SwoftDisplay display : Set.copyOf(DISPLAYS)) {
            display.destroy();
        }
    }
}
