package net.swofty.ui;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.title.Title;
import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Player;
import net.minestom.server.event.player.PlayerDisconnectEvent;
import net.minestom.server.scoreboard.BelowNameTag;
import net.minestom.server.timer.ExecutionType;
import net.minestom.server.timer.TaskSchedule;
import net.swofty.ScriptError;
import net.swofty.TextFormat;
import net.swofty.async.TickDispatch;
import net.swofty.model.BossbarModel;
import net.swofty.model.ScoreboardModel;
import net.swofty.model.TablistModel;
import net.swofty.nativebridge.execution.commands.ui.BelownameStatement;
import net.swofty.nativebridge.execution.commands.ui.SetBossbarPartStatement;
import net.swofty.nativebridge.execution.commands.ui.SetTablistPartStatement;
import net.swofty.props.Coercions;
import net.swofty.props.NoneValue;

/**
 * Static facade for scoreboards, tablists, bossbars, titles, actionbars and
 * belowname. Targets are evaluated script values: a Player, a collection of
 * players, or the string "all". Structured-state operations hop to the tick
 * thread; pure-packet sends (title/actionbar) go direct.
 */
public final class UiRuntime {
    private static final int TITLE_DEFAULT_FADE_IN = 10;
    private static final int TITLE_DEFAULT_STAY = 70;
    private static final int TITLE_DEFAULT_FADE_OUT = 20;

    private static final Map<UUID, BelowNameTag> BELOWNAME_TAGS = new ConcurrentHashMap<>();
    private static volatile boolean initialized;

    private UiRuntime() {
    }

    /**
     * Register the disconnect cleanup listener; call once after
     * MinecraftServer.init()
     */
    public static void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        MinecraftServer.getGlobalEventHandler().addListener(PlayerDisconnectEvent.class, event -> {
            Player player = event.getPlayer();
            SwoftSidebarRuntime.disconnect(player);
            SwoftTablistRuntime.disconnect(player);
            SwoftBossbarRuntime.disconnect(player);
            BELOWNAME_TAGS.remove(player.getUuid());
        });
    }

    /**
     * Cancel every live scoreboard/tablist/bossbar auto-refresh task before a
     * reload re-registers the fresh declaration set. Live viewers are kept;
     * the register pass re-arms tasks (with freshly-parsed models / line
     * numbers) for the boards that still exist, so removed boards stop
     * refreshing instead of leaking a stale-model task on every reload.
     */
    public static void clearTasks() {
        SwoftSidebarRuntime.clearTasks();
        SwoftTablistRuntime.clearTasks();
        SwoftBossbarRuntime.clearTasks();
    }

    public static void register(ScoreboardModel scoreboard) {
        SwoftSidebarRuntime.register(scoreboard);
    }

    public static void register(TablistModel tablist) {
        SwoftTablistRuntime.register(tablist);
    }

    public static void register(BossbarModel bossbar) {
        SwoftBossbarRuntime.register(bossbar);
    }

    public static void showScoreboard(String name, Object target) {
        onTick(target, "show scoreboard", player -> SwoftSidebarRuntime.show(name, player));
    }

    public static void hideScoreboard(Object target) {
        onTick(target, "hide scoreboard", SwoftSidebarRuntime::hide);
    }

    public static void updateScoreboard(Object target) {
        onTick(target, "update scoreboard", SwoftSidebarRuntime::update);
    }

    public static void showTablist(String name, Object target) {
        onTick(target, "show tablist", player -> SwoftTablistRuntime.show(name, player));
    }

    public static void hideTablist(Object target) {
        onTick(target, "hide tablist", SwoftTablistRuntime::hide);
    }

    public static void setTablistPart(SetTablistPartStatement.Part part, String value, Object target) {
        Component component = TextFormat.component(value);
        boolean header = part == SetTablistPartStatement.Part.HEADER;
        onTick(target, "set tablist part",
                player -> SwoftTablistRuntime.setPart(header, component, player));
    }

    public static void showTitle(Object target, String title, String subtitle,
                                 Integer fadeInTicks, Integer stayTicks, Integer fadeOutTicks) {
        Title.Times times = fadeInTicks == null && stayTicks == null && fadeOutTicks == null
                ? Title.DEFAULT_TIMES
                : Title.Times.times(
                        ticksDuration(fadeInTicks, TITLE_DEFAULT_FADE_IN),
                        ticksDuration(stayTicks, TITLE_DEFAULT_STAY),
                        ticksDuration(fadeOutTicks, TITLE_DEFAULT_FADE_OUT));
        Title full = Title.title(TextFormat.component(title),
                subtitle != null ? TextFormat.component(subtitle) : Component.empty(),
                times);
        for (Player player : targets(target, "title")) {
            player.showTitle(full);
        }
    }

    public static void clearTitle(Object target) {
        for (Player player : targets(target, "clear title")) {
            player.resetTitle();
        }
    }

    /**
     * Plain form is a single send; `for <duration>` re-sends every 2 ticks
     * so the bar does not fade out early
     */
    public static void actionbar(Object target, String text, Integer durationTicks) {
        Component component = TextFormat.component(text);
        for (Player player : targets(target, "actionbar")) {
            player.sendActionBar(component);
            if (durationTicks != null && durationTicks > 2) {
                AtomicInteger remaining = new AtomicInteger(durationTicks - 2);
                MinecraftServer.getSchedulerManager().submitTask(() -> {
                    if (!player.isOnline() || remaining.addAndGet(-2) < 0) {
                        return TaskSchedule.stop();
                    }
                    player.sendActionBar(component);
                    return TaskSchedule.tick(2);
                }, ExecutionType.TICK_END);
            }
        }
    }

    public static void showBossbar(String name, Object target) {
        onTick(target, "show bossbar", player -> SwoftBossbarRuntime.show(name, player));
    }

    public static void hideBossbar(String name, Object target) {
        onTick(target, "hide bossbar", player -> SwoftBossbarRuntime.hide(name, player));
    }

    public static void setBossbarPart(String name, SetBossbarPartStatement.Part part,
                                      Object value, Object target) {
        boolean progress = part == SetBossbarPartStatement.Part.PROGRESS;
        onTick(target, "set bossbar part",
                player -> SwoftBossbarRuntime.setPart(name, progress, value, player));
    }

    public static void belowname(BelownameStatement.Action action, Object value, Object target) {
        onTick(target, "belowname", player -> {
            switch (action) {
                case TEXT -> {
                    clearBelowname(player);
                    BelowNameTag tag = new BelowNameTag("swoft",
                            (Component) Coercions.toComponent(value));
                    BELOWNAME_TAGS.put(player.getUuid(), tag);
                    player.setBelowNameTag(tag);
                    // setBelowNameTag does not add viewers itself (known
                    // Minestom gap the reference works around the same way)
                    tag.addViewer(player);
                    for (Player viewer : player.getViewers()) {
                        tag.addViewer(viewer);
                    }
                }
                case SCORE -> {
                    BelowNameTag tag = BELOWNAME_TAGS.get(player.getUuid());
                    if (tag == null) {
                        throw new ScriptError("no belowname set for " + player.getUsername()
                                + "; use belowname \"<text>\" for <player> first");
                    }
                    tag.updateScore(player,
                            Coercions.requireNumber(value, "belowname score").intValue());
                }
                case CLEAR -> {
                    clearBelowname(player);
                    player.setBelowNameTag(null);
                }
            }
        });
    }

    private static void clearBelowname(Player player) {
        BelowNameTag previous = BELOWNAME_TAGS.remove(player.getUuid());
        if (previous != null) {
            for (Player viewer : new ArrayList<>(previous.getViewers())) {
                previous.removeViewer(viewer);
            }
        }
    }

    private interface PlayerAction {
        void accept(Player player);
    }

    private static void onTick(Object target, String what, PlayerAction action) {
        List<Player> players = targets(target, what);
        TickDispatch.call(() -> {
            for (Player player : players) {
                action.accept(player);
            }
            return null;
        });
    }

    private static List<Player> targets(Object value, String what) {
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
        if ("all".equals(value)) {
            return new ArrayList<>(MinecraftServer.getConnectionManager().getOnlinePlayers());
        }
        if (NoneValue.isNone(value)) {
            throw new ScriptError(what + " target is none");
        }
        throw new ScriptError(what + " expects a player, a list of players, or all, got: " + value);
    }

    private static Duration ticksDuration(Integer ticks, int fallback) {
        return Duration.ofMillis((ticks != null ? ticks : fallback) * 50L);
    }
}
