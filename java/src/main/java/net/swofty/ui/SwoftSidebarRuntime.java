package net.swofty.ui;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.kyori.adventure.text.Component;
import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Player;
import net.minestom.server.scoreboard.Sidebar;
import net.minestom.server.timer.ExecutionType;
import net.minestom.server.timer.Task;
import net.minestom.server.timer.TaskSchedule;
import net.swofty.ScriptError;
import net.swofty.model.ScoreboardModel;
import net.swofty.model.UpdateCadence;
import net.swofty.props.Coercions;

/**
 * Port of the reference HypixelScoreboard diff layer: one Sidebar per
 * (declaration, player), line ids "line_i", score = count-1-i so lines
 * render top-down, NumberFormat.blank() hiding the red numbers by default.
 * A player sees at most one sidebar at a time.
 */
public final class SwoftSidebarRuntime {
    private static final int MAX_LINES = 15;

    private static final class View {
        final Player player;
        final String decl;
        final Sidebar sidebar;
        List<Component> lines = List.of();
        Component title;

        View(Player player, String decl, Sidebar sidebar, Component title) {
            this.player = player;
            this.decl = decl;
            this.sidebar = sidebar;
            this.title = title;
        }
    }

    private static final Map<String, ScoreboardModel> DECLS = new ConcurrentHashMap<>();
    private static final Map<UUID, View> VIEWS = new ConcurrentHashMap<>();
    /**
     * Live auto-refresh tasks keyed by declaration name. A hot reload
     * re-registers each board from a freshly-parsed model: the previous task
     * (which captured the OLD model, hence stale line numbers) is cancelled
     * and replaced so refreshes trace the new code. Never wiped by name, so
     * live viewers keep their sidebar across a reload.
     */
    private static final Map<String, Task> TASKS = new ConcurrentHashMap<>();

    private SwoftSidebarRuntime() {
    }

    public static void register(ScoreboardModel model) {
        DECLS.put(model.name(), model);
        Task previous = TASKS.remove(model.name());
        if (previous != null) {
            previous.cancel();
        }
        if (model.update().kind() == UpdateCadence.Kind.TICKS) {
            Task task = MinecraftServer.getSchedulerManager().submitTask(() -> {
                refreshAll(model);
                return TaskSchedule.tick(model.update().ticks());
            }, ExecutionType.TICK_END);
            TASKS.put(model.name(), task);
        }
    }

    /**
     * Cancel every live auto-refresh task (reload teardown). Declarations and
     * live viewers are left intact; the fresh register() pass re-arms the
     * tasks for boards that still exist, so a removed board simply stops
     * refreshing instead of leaking a stale-model task forever.
     */
    public static void clearTasks() {
        for (Task task : TASKS.values()) {
            task.cancel();
        }
        TASKS.clear();
    }

    /** Live auto-refresh task count (diagnostics/tests: one per ticking board). */
    public static int taskCount() {
        return TASKS.size();
    }

    public static void show(String name, Player player) {
        ScoreboardModel model = lookup(name);
        View view = VIEWS.get(player.getUuid());
        if (view != null && !view.decl.equals(name)) {
            hide(player);
            view = null;
        }
        if (view == null) {
            Component title = evalTitle(model, player);
            Sidebar sidebar = new Sidebar(title);
            view = new View(player, name, sidebar, title);
            VIEWS.put(player.getUuid(), view);
            sidebar.addViewer(player);
        }
        refresh(model, view);
    }

    public static void hide(Player player) {
        View view = VIEWS.remove(player.getUuid());
        if (view != null) {
            view.sidebar.removeViewer(player);
        }
    }

    /**
     * Force one refresh now (the whole surface for update: manual boards)
     */
    public static void update(Player player) {
        View view = VIEWS.get(player.getUuid());
        if (view != null) {
            ScoreboardModel model = DECLS.get(view.decl);
            if (model != null) {
                refresh(model, view);
            }
        }
    }

    public static void disconnect(Player player) {
        hide(player);
    }

    private static void refreshAll(ScoreboardModel model) {
        for (View view : VIEWS.values()) {
            if (view.decl.equals(model.name()) && view.player.isOnline()) {
                try {
                    refresh(model, view);
                } catch (Exception e) {
                    System.err.println("Scoreboard '" + model.name() + "' refresh failed: " + e);
                }
            }
        }
    }

    private static void refresh(ScoreboardModel model, View view) {
        Component title = evalTitle(model, view.player);
        if (!title.equals(view.title)) {
            view.sidebar.setTitle(title);
            view.title = title;
        }

        List<Component> lines = new ArrayList<>();
        UiBodyExecutor.run(view.player, model.lines(), new UiBodyExecutor.Sink() {
            @Override
            public void line(Component content) {
                lines.add(content);
            }
        });
        if (lines.size() > MAX_LINES) {
            System.err.println("Scoreboard '" + model.name() + "' emitted " + lines.size()
                    + " lines for " + view.player.getUsername() + "; truncating to " + MAX_LINES);
            lines.subList(MAX_LINES, lines.size()).clear();
        }

        List<Component> old = view.lines;
        int common = Math.min(old.size(), lines.size());
        boolean sizeChanged = old.size() != lines.size();
        for (int i = 0; i < common; i++) {
            if (!lines.get(i).equals(old.get(i))) {
                view.sidebar.updateLineContent("line_" + i, lines.get(i));
            }
            if (sizeChanged) {
                view.sidebar.updateLineScore("line_" + i, lines.size() - 1 - i);
            }
        }
        for (int i = old.size(); i < lines.size(); i++) {
            view.sidebar.createLine(model.numbersHidden()
                    ? new Sidebar.ScoreboardLine("line_" + i, lines.get(i),
                            lines.size() - 1 - i, Sidebar.NumberFormat.blank())
                    : new Sidebar.ScoreboardLine("line_" + i, lines.get(i),
                            lines.size() - 1 - i));
        }
        for (int i = lines.size(); i < old.size(); i++) {
            view.sidebar.removeLine("line_" + i);
        }
        view.lines = lines;
    }

    private static Component evalTitle(ScoreboardModel model, Player player) {
        UiBodyExecutor executor = new UiBodyExecutor(player, new UiBodyExecutor.Sink() {
        });
        return (Component) Coercions.toComponent(executor.evaluateExpression(model.title()));
    }

    private static ScoreboardModel lookup(String name) {
        ScoreboardModel model = DECLS.get(name);
        if (model == null) {
            throw new ScriptError("unknown scoreboard '" + name + "'");
        }
        return model;
    }
}
