package net.swofty.ui;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.kyori.adventure.bossbar.BossBar;
import net.kyori.adventure.text.Component;
import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Player;
import net.minestom.server.timer.ExecutionType;
import net.minestom.server.timer.Task;
import net.minestom.server.timer.TaskSchedule;
import net.swofty.ScriptError;
import net.swofty.model.BossbarModel;
import net.swofty.model.UpdateCadence;
import net.swofty.props.Coercions;

/**
 * One adventure BossBar per (declaration, player); updates mutate name and
 * progress in place — Minestom's BossBarHolder pushes the packets to
 * viewers automatically.
 */
public final class SwoftBossbarRuntime {
    private static final class View {
        final Player player;
        final BossBar bar;

        View(Player player, BossBar bar) {
            this.player = player;
            this.bar = bar;
        }
    }

    private static final Map<String, BossbarModel> DECLS = new ConcurrentHashMap<>();
    private static final Map<String, Map<UUID, View>> VIEWS = new ConcurrentHashMap<>();
    /**
     * Live auto-update tasks keyed by declaration name. A hot reload cancels
     * and replaces the previous task (which captured the OLD model / line
     * numbers) so updates trace the freshly-parsed code; live viewers are kept.
     */
    private static final Map<String, Task> TASKS = new ConcurrentHashMap<>();

    private SwoftBossbarRuntime() {
    }

    public static void register(BossbarModel model) {
        DECLS.put(model.name(), model);
        VIEWS.putIfAbsent(model.name(), new ConcurrentHashMap<>());
        Task previous = TASKS.remove(model.name());
        if (previous != null) {
            previous.cancel();
        }
        if (model.update().kind() == UpdateCadence.Kind.TICKS) {
            Task task = MinecraftServer.getSchedulerManager().submitTask(() -> {
                updateAll(model);
                return TaskSchedule.tick(model.update().ticks());
            }, ExecutionType.TICK_END);
            TASKS.put(model.name(), task);
        }
    }

    /** Cancel every live auto-update task (reload teardown); viewers kept. */
    public static void clearTasks() {
        for (Task task : TASKS.values()) {
            task.cancel();
        }
        TASKS.clear();
    }

    public static void show(String name, Player player) {
        BossbarModel model = lookup(name);
        Map<UUID, View> views = VIEWS.get(name);
        View existing = views.get(player.getUuid());
        if (existing != null) {
            refresh(model, existing);
            return;
        }
        BossBar bar = BossBar.bossBar(text(model, player), progress(model, player),
                color(model.color()), overlay(model.style()));
        views.put(player.getUuid(), new View(player, bar));
        player.showBossBar(bar);
    }

    public static void hide(String name, Player player) {
        lookup(name);
        View view = VIEWS.get(name).remove(player.getUuid());
        if (view != null) {
            player.hideBossBar(view.bar);
        }
    }

    public static void setPart(String name, boolean progressPart, Object value, Player player) {
        View view = VIEWS.get(lookup(name).name()).get(player.getUuid());
        if (view == null) {
            return;
        }
        if (progressPart) {
            view.bar.progress(clampProgress(Coercions.requireNumber(value, "bossbar progress")));
        } else {
            view.bar.name((Component) Coercions.toComponent(value));
        }
    }

    public static void disconnect(Player player) {
        for (Map<UUID, View> views : VIEWS.values()) {
            views.remove(player.getUuid());
        }
        MinecraftServer.getBossBarManager().removeAllBossBars(player);
    }

    private static void updateAll(BossbarModel model) {
        for (View view : VIEWS.get(model.name()).values()) {
            if (view.player.isOnline()) {
                try {
                    refresh(model, view);
                } catch (Exception e) {
                    System.err.println("Bossbar '" + model.name() + "' update failed: " + e);
                }
            }
        }
    }

    private static void refresh(BossbarModel model, View view) {
        view.bar.name(text(model, view.player));
        view.bar.progress(progress(model, view.player));
    }

    private static Component text(BossbarModel model, Player player) {
        UiBodyExecutor executor = new UiBodyExecutor(player, new UiBodyExecutor.Sink() {
        });
        return (Component) Coercions.toComponent(executor.evaluateExpression(model.text()));
    }

    private static float progress(BossbarModel model, Player player) {
        UiBodyExecutor executor = new UiBodyExecutor(player, new UiBodyExecutor.Sink() {
        });
        Object value = executor.evaluateExpression(model.progress());
        return clampProgress(Coercions.requireNumber(value, "bossbar progress"));
    }

    private static float clampProgress(Number value) {
        return Math.clamp(value.floatValue(), 0f, 1f);
    }

    private static BossBar.Color color(String name) {
        return switch (name) {
            case "pink" -> BossBar.Color.PINK;
            case "blue" -> BossBar.Color.BLUE;
            case "red" -> BossBar.Color.RED;
            case "green" -> BossBar.Color.GREEN;
            case "yellow" -> BossBar.Color.YELLOW;
            case "purple" -> BossBar.Color.PURPLE;
            case "white" -> BossBar.Color.WHITE;
            default -> throw new ScriptError("unknown bossbar color '" + name + "'");
        };
    }

    private static BossBar.Overlay overlay(String name) {
        return switch (name) {
            case "progress" -> BossBar.Overlay.PROGRESS;
            case "notched_6" -> BossBar.Overlay.NOTCHED_6;
            case "notched_10" -> BossBar.Overlay.NOTCHED_10;
            case "notched_12" -> BossBar.Overlay.NOTCHED_12;
            case "notched_20" -> BossBar.Overlay.NOTCHED_20;
            default -> throw new ScriptError("unknown bossbar style '" + name + "'");
        };
    }

    private static BossbarModel lookup(String name) {
        BossbarModel model = DECLS.get(name);
        if (model == null) {
            throw new ScriptError("unknown bossbar '" + name + "'");
        }
        return model;
    }
}
