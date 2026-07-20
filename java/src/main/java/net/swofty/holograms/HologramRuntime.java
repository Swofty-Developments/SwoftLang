package net.swofty.holograms;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.coordinate.Vec;
import net.minestom.server.entity.Player;
import net.minestom.server.instance.Instance;
import net.minestom.server.timer.ExecutionType;
import net.minestom.server.timer.Task;
import net.minestom.server.timer.TaskSchedule;
import net.swofty.ASTExecutor;
import net.swofty.InstanceRegistry;
import net.swofty.ScriptError;
import net.swofty.displays.SwoftDisplay;
import net.swofty.handlers.HandlerDispatch;
import net.swofty.model.HologramModel;
import net.swofty.model.InlineHandler;
import net.swofty.model.UpdateCadence;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.nativebridge.execution.commands.ui.LineStatement;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.props.Coercions;
import net.swofty.props.NoneValue;

/**
 * First-class {@code hologram "name" { ... }} runtime (design 6C). Supersedes
 * the hand-rolled {@code addons/holograms.sw} closure-chain store.
 *
 * <p>Each hologram owns a <b>stack</b> of {@link SwoftDisplay} TEXT entities,
 * one per rendered line, stacked downward at {@code -0.28} blocks per line,
 * with the declaration's billboard + scale applied. Two scopes:
 * <ul>
 *   <li><b>Global</b> ({@code perViewer == false}) — a single shared stack.
 *       {@code show ... to all} makes the displays auto-viewable (future
 *       joiners see them); {@code show ... to <player>} reveals per-viewer via
 *       {@link SwoftDisplay#show(Player)}.</li>
 *   <li><b>Per-player</b> ({@code perViewer == true}) — a private stack per
 *       viewer whose lines are re-rendered through an {@link ASTExecutor}
 *       child env with {@code player} bound, exactly like scoreboards.</li>
 * </ul>
 *
 * <p>The update cadence re-renders dynamic/interpolated lines and
 * <b>diff-renders</b>: only lines whose text changed are pushed to the
 * client; the stack grows/shrinks by spawning/destroying only the delta.
 * Cleanup happens on hide/remove/disconnect and via {@link #teardown()} for
 * hot-reload (#58).
 */
public final class HologramRuntime {
    /** Vertical gap between stacked lines, in blocks. */
    private static final double LINE_OFFSET = 0.28;
    private static final int MAX_LINES = 40;

    /** One rendered stack of text-display entities (global or per-viewer). */
    private static final class Stack {
        final List<SwoftDisplay> displays = new ArrayList<>();
        List<String> lines = List.of();
    }

    private static final class Hologram {
        final HologramModel model;
        final String billboard;
        /** Manual per-line overrides from {@code set hologram line N to ...}. */
        final Map<Integer, String> overrides = new ConcurrentHashMap<>();
        /** Per-viewer private stacks (perViewer holograms). */
        final Map<UUID, Stack> viewers = new ConcurrentHashMap<>();
        /** Explicit per-player viewers of a global stack (non auto-all). */
        final Set<UUID> globalViewers = ConcurrentHashMap.newKeySet();

        volatile Stack global;
        volatile Instance globalInstance;
        volatile boolean globalShownAll;
        volatile Pos base;
        volatile double scale = 1.0;
        volatile boolean evaluated;

        Hologram(HologramModel model) {
            this.model = model;
            String bb = model.billboard();
            this.billboard = (bb == null || bb.isBlank()) ? "center" : bb.toLowerCase();
        }
    }

    private static final Map<String, Hologram> HOLOS = new ConcurrentHashMap<>();
    private static final Map<String, Task> TASKS = new ConcurrentHashMap<>();
    /** Per-tick on_tick handler tasks, one per hologram that declares on_tick. */
    private static final Map<String, Task> TICK_TASKS = new ConcurrentHashMap<>();

    private static volatile boolean initialized = false;

    private HologramRuntime() {
    }

    // ------------------------------------------------------------------
    // one-time listener wiring
    // ------------------------------------------------------------------

    /**
     * Wire the per-viewer cleanup listener once. A disconnecting player's
     * private per-viewer stacks (and their text-display entities) must be
     * destroyed, or they leak on every logout.
     */
    public static synchronized void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        MinecraftServer.getGlobalEventHandler().addListener(
                net.minestom.server.event.player.PlayerDisconnectEvent.class,
                event -> disconnect(event.getPlayer()));
    }

    // ------------------------------------------------------------------
    // registration + update cadence
    // ------------------------------------------------------------------

    public static void register(HologramModel model) {
        Hologram holo = new Hologram(model);
        HOLOS.put(model.name(), holo);
        if (model.update().kind() == UpdateCadence.Kind.TICKS) {
            int ticks = Math.max(1, model.update().ticks());
            Task task = MinecraftServer.getSchedulerManager().submitTask(() -> {
                try {
                    refresh(HOLOS.get(model.name()));
                } catch (Exception e) {
                    System.err.println("Hologram '" + model.name() + "' refresh failed: " + e);
                }
                return TaskSchedule.tick(ticks);
            }, ExecutionType.TICK_END);
            TASKS.put(model.name(), task);
        }
        // on_tick(): fires every tick while the decl is active, independent of
        // the update cadence. Guard cost — the per-tick task is created ONLY
        // when the hologram declares on_tick, so holograms without one pay
        // nothing (no scheduled work at all).
        if (model.handler("on_tick") != null) {
            Task tick = MinecraftServer.getSchedulerManager().submitTask(() -> {
                try {
                    tickHologram(HOLOS.get(model.name()));
                } catch (Exception e) {
                    System.err.println("Hologram '" + model.name() + "' on_tick failed: " + e);
                }
                return TaskSchedule.tick(1);
            }, ExecutionType.TICK_END);
            TICK_TASKS.put(model.name(), tick);
        }
    }

    /**
     * Fire the hologram's {@code on_tick} handler for each live stack, binding
     * {@code this} (TDisplay) to that stack's first text-display line so the
     * body can read/write display props such as {@code this.text}. A global
     * hologram has one stack (bound once); a per-viewer hologram fires once per
     * viewer's private stack. When no stack is live yet (the hologram has not
     * been shown), there is no display to bind, so on_tick is a no-op that
     * tick. Reuses the shared {@link HandlerDispatch} machinery the mob/npc
     * on_tick paths use.
     */
    private static void tickHologram(Hologram holo) {
        if (holo == null) {
            return;
        }
        InlineHandler handler = holo.model.handler("on_tick");
        if (handler == null) {
            return;
        }
        if (holo.model.perViewer()) {
            for (Stack stack : holo.viewers.values()) {
                dispatchTick(holo, handler, stack);
            }
        } else if (holo.global != null) {
            dispatchTick(holo, handler, holo.global);
        }
    }

    private static void dispatchTick(Hologram holo, InlineHandler handler, Stack stack) {
        if (stack.displays.isEmpty()) {
            return;
        }
        HandlerDispatch.dispatch(handler, stack.displays.get(0), null,
                "hologram '" + holo.model.name() + "' on_tick");
    }

    // ------------------------------------------------------------------
    // statements: show / hide / move / set-line / remove
    // ------------------------------------------------------------------

    /** {@code show hologram "name" to <player|all>}. */
    public static void show(String name, Object target) {
        Hologram holo = require(name);
        evalConstants(holo);
        if (holo.model.perViewer()) {
            for (Player player : targets(target, "show hologram")) {
                showPerViewer(holo, player);
            }
            return;
        }
        ensureGlobal(holo);
        if (isAll(target)) {
            holo.globalShownAll = true;
            for (SwoftDisplay display : holo.global.displays) {
                display.showAll();
            }
        } else {
            for (Player player : targets(target, "show hologram")) {
                holo.globalViewers.add(player.getUuid());
                for (SwoftDisplay display : holo.global.displays) {
                    display.show(player);
                }
            }
        }
    }

    /** {@code hide hologram "name" from <player|all>}. */
    public static void hide(String name, Object target) {
        Hologram holo = require(name);
        if (holo.model.perViewer()) {
            if (isAll(target)) {
                for (UUID id : Set.copyOf(holo.viewers.keySet())) {
                    destroyStack(holo.viewers.remove(id));
                }
            } else {
                for (Player player : targets(target, "hide hologram")) {
                    destroyStack(holo.viewers.remove(player.getUuid()));
                }
            }
            return;
        }
        if (holo.global == null) {
            return;
        }
        if (isAll(target)) {
            holo.globalShownAll = false;
            holo.globalViewers.clear();
            for (SwoftDisplay display : holo.global.displays) {
                display.hideAll();
            }
        } else {
            for (Player player : targets(target, "hide hologram")) {
                holo.globalViewers.remove(player.getUuid());
                for (SwoftDisplay display : holo.global.displays) {
                    display.hide(player);
                }
            }
        }
    }

    /** {@code move hologram "name" to <location>}. */
    public static void move(String name, Object location) {
        Hologram holo = require(name);
        Pos base = (Pos) Coercions.toPos(location);
        holo.base = base;
        if (holo.global != null) {
            reposition(holo.global, base);
        }
        for (Stack stack : holo.viewers.values()) {
            reposition(stack, base);
        }
    }

    /** {@code set hologram "name" line <n> to <expr>} (0-based). */
    public static void setLine(String name, int index, Object value) {
        Hologram holo = require(name);
        if (index < 0) {
            throw new ScriptError("hologram line index must be >= 0, got " + index);
        }
        holo.overrides.put(index, String.valueOf(Coercions.toStringValue(value)));
        refresh(holo);
    }

    /** {@code remove hologram "name"} — destroy every stack and stop updates. */
    public static void remove(String name) {
        Hologram holo = HOLOS.remove(name);
        Task task = TASKS.remove(name);
        if (task != null) {
            task.cancel();
        }
        Task tick = TICK_TASKS.remove(name);
        if (tick != null) {
            tick.cancel();
        }
        if (holo != null) {
            destroyAll(holo);
        }
    }

    /** Force one re-render now (manual-cadence holograms). */
    public static void update(String name) {
        refresh(HOLOS.get(name));
    }

    /** The declaration model for a hologram, or null. */
    public static HologramModel modelFor(String name) {
        Hologram holo = HOLOS.get(name);
        return holo == null ? null : holo.model;
    }

    /**
     * The name of the hologram whose display stack owns {@code entityId}, or
     * null. Backs the inline {@code on_click} dispatch (W-inline-handlers):
     * when a player interacts with a text-display entity that belongs to a
     * hologram, the dispatcher runs that hologram's handler.
     */
    public static String holoNameForEntity(int entityId) {
        for (Map.Entry<String, Hologram> entry : HOLOS.entrySet()) {
            Hologram holo = entry.getValue();
            if (holo.global != null && stackHasEntity(holo.global, entityId)) {
                return entry.getKey();
            }
            for (Stack stack : holo.viewers.values()) {
                if (stackHasEntity(stack, entityId)) {
                    return entry.getKey();
                }
            }
        }
        return null;
    }

    private static boolean stackHasEntity(Stack stack, int entityId) {
        for (SwoftDisplay display : stack.displays) {
            if (display.entity() != null && display.entity().getEntityId() == entityId) {
                return true;
            }
        }
        return false;
    }

    // ------------------------------------------------------------------
    // lifecycle: disconnect + hot-reload teardown
    // ------------------------------------------------------------------

    public static void disconnect(Player player) {
        UUID id = player.getUuid();
        for (Hologram holo : HOLOS.values()) {
            destroyStack(holo.viewers.remove(id));
            holo.globalViewers.remove(id);
        }
    }

    /** Tear down every hologram (hot-reload #58): cancel tasks, kill entities. */
    public static void teardown() {
        for (Task task : TASKS.values()) {
            task.cancel();
        }
        TASKS.clear();
        for (Task task : TICK_TASKS.values()) {
            task.cancel();
        }
        TICK_TASKS.clear();
        for (Hologram holo : HOLOS.values()) {
            destroyAll(holo);
        }
        HOLOS.clear();
    }

    // ------------------------------------------------------------------
    // rendering + diff
    // ------------------------------------------------------------------

    private static void refresh(Hologram holo) {
        if (holo == null) {
            return;
        }
        evalConstants(holo);
        if (holo.model.perViewer()) {
            for (Map.Entry<UUID, Stack> entry : holo.viewers.entrySet()) {
                Player player = MinecraftServer.getConnectionManager().getOnlinePlayerByUuid(entry.getKey());
                if (player == null || !player.isOnline()) {
                    destroyStack(holo.viewers.remove(entry.getKey()));
                    continue;
                }
                renderInto(holo, entry.getValue(), player, instanceFor(player), true);
            }
        } else if (holo.global != null) {
            renderInto(holo, holo.global, null, holo.globalInstance, false);
        }
    }

    private static void showPerViewer(Hologram holo, Player player) {
        Stack stack = holo.viewers.computeIfAbsent(player.getUuid(), k -> new Stack());
        renderInto(holo, stack, player, instanceFor(player), true);
    }

    private static void ensureGlobal(Hologram holo) {
        if (holo.global == null) {
            holo.globalInstance = instanceFor(null);
            holo.global = new Stack();
            renderInto(holo, holo.global, null, holo.globalInstance, false);
        }
    }

    /**
     * Render {@code holo}'s lines for {@code viewer} (null = global scope) and
     * diff them into {@code stack}: unchanged lines are left untouched, changed
     * lines have their text updated, and the stack grows/shrinks by
     * spawning/destroying only the delta.
     */
    private static void renderInto(Hologram holo, Stack stack, Player viewer,
            Instance instance, boolean privateToViewer) {
        List<String> next = render(holo, viewer);
        if (next.size() > MAX_LINES) {
            next.subList(MAX_LINES, next.size()).clear();
        }
        List<String> old = stack.lines;
        Pos base = holo.base;

        int common = Math.min(old.size(), next.size());
        for (int i = 0; i < common; i++) {
            if (!next.get(i).equals(old.get(i))) {
                stack.displays.get(i).setText(next.get(i));
            }
        }
        for (int i = old.size(); i < next.size(); i++) {
            SwoftDisplay display = createDisplay(holo, next.get(i));
            if (privateToViewer) {
                // manual + hidden before spawn so it never leaks to the world
                display.hideAll();
                display.spawn(instance, linePos(base, i));
                display.show(viewer);
            } else {
                display.hideAll();
                display.spawn(instance, linePos(base, i));
                applyGlobalVisibility(holo, display);
            }
            stack.displays.add(display);
        }
        for (int i = stack.displays.size() - 1; i >= next.size(); i--) {
            stack.displays.remove(i).destroy();
        }
        stack.lines = next;
    }

    private static List<String> render(Hologram holo, Player viewer) {
        List<String> out = new ArrayList<>();
        new HoloBodyExecutor(viewer, out::add).execute(holo.model.lines());
        if (!holo.overrides.isEmpty()) {
            int max = out.size();
            for (int idx : holo.overrides.keySet()) {
                max = Math.max(max, idx + 1);
            }
            while (out.size() < max) {
                out.add(" ");
            }
            for (Map.Entry<Integer, String> entry : holo.overrides.entrySet()) {
                int idx = entry.getKey();
                if (idx >= 0 && idx < out.size()) {
                    out.set(idx, entry.getValue());
                }
            }
        }
        return out;
    }

    private static SwoftDisplay createDisplay(Hologram holo, String text) {
        SwoftDisplay display = new SwoftDisplay(SwoftDisplay.Kind.TEXT);
        display.setText(text);
        display.setBillboard(holo.billboard);
        if (holo.scale != 1.0) {
            display.setScale(new Vec(holo.scale, holo.scale, holo.scale));
        }
        return display;
    }

    /** Re-apply the global stack's current visibility to a freshly-made line. */
    private static void applyGlobalVisibility(Hologram holo, SwoftDisplay display) {
        if (holo.globalShownAll) {
            display.showAll();
            return;
        }
        for (UUID id : holo.globalViewers) {
            Player player = MinecraftServer.getConnectionManager().getOnlinePlayerByUuid(id);
            if (player != null) {
                display.show(player);
            }
        }
    }

    private static void reposition(Stack stack, Pos base) {
        for (int i = 0; i < stack.displays.size(); i++) {
            stack.displays.get(i).teleport(linePos(base, i));
        }
    }

    private static Pos linePos(Pos base, int index) {
        return new Pos(base.x(), base.y() - LINE_OFFSET * index, base.z());
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    private static void evalConstants(Hologram holo) {
        if (holo.evaluated) {
            return;
        }
        synchronized (holo) {
            if (holo.evaluated) {
                return;
            }
            HoloBodyExecutor executor = new HoloBodyExecutor(null, s -> {
            });
            holo.base = (Pos) Coercions.toPos(executor.evaluateExpression(holo.model.location()));
            if (holo.model.scale() != null) {
                holo.scale = Coercions.requireNumber(
                        executor.evaluateExpression(holo.model.scale()), "hologram scale").doubleValue();
            }
            holo.evaluated = true;
        }
    }

    private static void destroyAll(Hologram holo) {
        destroyStack(holo.global);
        holo.global = null;
        for (UUID id : Set.copyOf(holo.viewers.keySet())) {
            destroyStack(holo.viewers.remove(id));
        }
        holo.globalViewers.clear();
        holo.globalShownAll = false;
    }

    private static void destroyStack(Stack stack) {
        if (stack == null) {
            return;
        }
        for (SwoftDisplay display : stack.displays) {
            display.destroy();
        }
        stack.displays.clear();
        stack.lines = List.of();
    }

    private static Instance instanceFor(Player player) {
        if (player != null && player.getInstance() != null) {
            return player.getInstance();
        }
        Instance world = InstanceRegistry.get("world");
        if (world != null) {
            return world;
        }
        for (Instance instance : MinecraftServer.getInstanceManager().getInstances()) {
            return instance;
        }
        throw new ScriptError("hologram: no world to spawn into");
    }

    private static boolean isAll(Object target) {
        return "all".equals(target) || NoneValue.isNone(target);
    }

    private static List<Player> targets(Object value, String what) {
        if (isAll(value)) {
            return new ArrayList<>(MinecraftServer.getConnectionManager().getOnlinePlayers());
        }
        if (value instanceof Player player) {
            return List.of(player);
        }
        if (value instanceof Collection<?> collection) {
            List<Player> players = new ArrayList<>();
            for (Object element : collection) {
                if (element instanceof Player player) {
                    players.add(player);
                }
            }
            return players;
        }
        throw new ScriptError(what + " expects a player, a list of players, or all, got: " + value);
    }

    private static Hologram require(String name) {
        Hologram holo = HOLOS.get(name);
        if (holo == null) {
            throw new ScriptError("unknown hologram '" + name + "'");
        }
        return holo;
    }

    // ------------------------------------------------------------------
    // test hooks (harness only)
    // ------------------------------------------------------------------

    /**
     * The rendered line texts of a hologram's stack for {@code viewer}: the
     * viewer's private per-viewer stack when perViewer, else the global stack.
     * Null when the hologram or that stack does not exist.
     */
    public static List<String> renderedLinesFor(String name, Player viewer) {
        Hologram holo = HOLOS.get(name);
        if (holo == null) {
            return null;
        }
        Stack stack = holo.model.perViewer()
                ? holo.viewers.get(viewer.getUuid())
                : holo.global;
        return stack == null ? null : List.copyOf(stack.lines);
    }

    /** Live count of spawned text-display entities for a viewer's stack. */
    public static int displayCountFor(String name, Player viewer) {
        Hologram holo = HOLOS.get(name);
        if (holo == null) {
            return 0;
        }
        Stack stack = holo.model.perViewer()
                ? holo.viewers.get(viewer.getUuid())
                : holo.global;
        return stack == null ? 0 : stack.displays.size();
    }

    /** Number of live per-viewer stacks (entity-leak check on disconnect). */
    public static int perViewerStackCount(String name) {
        Hologram holo = HOLOS.get(name);
        return holo == null ? 0 : holo.viewers.size();
    }

    /**
     * Test hook: is a per-tick {@code on_tick} task scheduled for this
     * hologram? Proves the guard — a task exists iff the decl declares on_tick.
     */
    public static boolean hasTickTask(String name) {
        return TICK_TASKS.containsKey(name);
    }

    /**
     * Test hook: run the {@code on_tick} handler once (headless, no tick loop)
     * and return the first global-stack display's live text, so a smoke can
     * observe that on_tick actually mutated the bound display. Null if there is
     * no global stack shown yet.
     */
    public static String tickOnceForTest(String name) {
        Hologram holo = HOLOS.get(name);
        if (holo == null) {
            return null;
        }
        tickHologram(holo);
        return holo.global != null && !holo.global.displays.isEmpty()
                ? holo.global.displays.get(0).getText()
                : null;
    }

    /**
     * Restricted lines{} executor: line/blank statements emit a rendered
     * MiniMessage string into the sink; per-viewer holograms bind {@code
     * player} so player-scoped interpolation resolves. Mirrors
     * {@link net.swofty.ui.UiBodyExecutor} but collects strings (a text
     * display holds one component per line, parsed on set).
     */
    private static final class HoloBodyExecutor extends ASTExecutor {
        interface Sink {
            void line(String text);
        }

        private final Sink sink;

        HoloBodyExecutor(CommandSender sender, Sink sink) {
            super(sender, initialVars(sender));
            this.sink = sink;
        }

        private static Map<String, Object> initialVars(CommandSender sender) {
            Map<String, Object> vars = new HashMap<>();
            if (sender instanceof Player player) {
                vars.put("player", player);
            }
            return vars;
        }

        @Override
        protected void emitUi(Statement statement) {
            if (statement instanceof LineStatement line) {
                sink.line(line.isBlank() ? " " : evaluateStringExpression(line.getText()));
            } else {
                throw new ScriptError(
                        "only line/blank statements are valid inside a hologram lines block");
            }
        }
    }
}
