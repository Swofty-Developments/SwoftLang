package net.swofty.persist.change;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import net.swofty.model.PersistChangeModel;
import net.swofty.model.PersistentDeclModel;
import net.swofty.persist.PersistStore;
import net.swofty.reload.ReloadRegistry;

/**
 * The armed set of declaration-attached change handlers (design 1.10.0 §4).
 *
 * <p>Handler BODIES come from the compiled program, so they are re-installed on
 * every load and every hot reload; the {@link PersistStore} and its values do
 * not (persistence deliberately survives a reload). That split is why this is a
 * separate registry with its own {@link ReloadRegistry} teardown: a reload drops
 * every handler and the re-registration pass installs the freshly-parsed ones,
 * so a removed or edited {@code on_change} can never leave a ghost handler
 * running the old body — while the values it reacts to keep their identity, and
 * the change SHADOWS are re-seeded from them (a reload is not a change).
 *
 * <p>When nothing declares a handler this is empty and {@link #armed()} is
 * false, which is the cheap gate every write path checks first — an unchanged
 * pre-1.10.0 program does no extra work.
 */
public final class ChangeRegistry {

    private static volatile Map<String, PersistChangeModel> handlers = Map.of();

    /**
     * Bumped by every {@link #install} and every {@link #reset}. A dispatch that
     * cannot run inline is parked on the next tick, so a hot reload can land
     * BETWEEN the write and the reaction; the parked batch carries the
     * generation it was built under and is dropped when it no longer matches.
     * That is what stops a queued reaction from running a torn-down handler
     * body against the freshly-loaded program — the same ghost-handler rule the
     * {@link ReloadRegistry} enforces for every other subsystem.
     */
    private static volatile long generation;

    private ChangeRegistry() {
    }

    /** The generation the currently-installed handlers belong to. */
    public static long generation() {
        return generation;
    }

    /**
     * Install the change handlers of the freshly-loaded declarations, arm the
     * reload teardown, and re-seed the shadows from whatever the store already
     * holds (so the first write after a load/reload compares against the real
     * value, not the declared default).
     */
    public static synchronized void install(List<PersistentDeclModel> decls) {
        Map<String, PersistChangeModel> next = new LinkedHashMap<>();
        if (decls != null) {
            for (PersistentDeclModel decl : decls) {
                if (decl.change() != null) {
                    next.put(decl.name(), decl.change());
                }
            }
        }
        handlers = Map.copyOf(next);
        generation++;
        if (next.isEmpty()) {
            return;
        }
        if (!ReloadRegistry.names().contains("persist-change")) {
            ReloadRegistry.register("persist-change", ChangeRegistry::reset);
        }
        // every LIVE store, not just the active one: a store cannot seed itself
        // at construction (the handlers arrive with the compiled program, after
        // it) and the two-server harness builds stores that are never active.
        PersistStore.seedAllChangeShadows();
        System.out.println("[persist] " + next.size()
                + " change handler(s) armed (on_change / on_entry_change)");
    }

    /** Drop every handler — the reload teardown, and the shutdown path. */
    public static synchronized void reset() {
        handlers = Map.of();
        generation++;
    }

    /** The handler declared for {@code var}, or null. */
    public static PersistChangeModel handlerFor(String var) {
        return handlers.get(var);
    }

    /** Whether any declaration carries a change handler at all. */
    public static boolean armed() {
        return !handlers.isEmpty();
    }
}
