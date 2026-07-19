package net.swofty.ui;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.kyori.adventure.text.Component;
import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.GameMode;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.PlayerSkin;
import net.minestom.server.network.packet.server.play.PlayerInfoRemovePacket;
import net.minestom.server.network.packet.server.play.PlayerInfoUpdatePacket;
import net.minestom.server.timer.ExecutionType;
import net.minestom.server.timer.TaskSchedule;
import net.swofty.ScriptError;
import net.swofty.model.TablistColumnModel;
import net.swofty.model.TablistModel;
import net.swofty.model.UpdateCadence;
import net.swofty.props.Coercions;

/**
 * Port of the reference TablistManager loop: per player per cycle the fake
 * entries are wiped with PlayerInfoRemovePacket and rebuilt. Deterministic
 * UUIDs (uuid + "#tab#" + slot), fake names "tab" + base36(slot), 9-arg
 * PlayerInfoUpdatePacket.Entry ordered via listOrder (no teams hack); the
 * client sorts DESCENDING by list order, so slots map to 10000 - slot to
 * render in declaration order and above real players. Columns wrap
 * client-side every 20 entries; fill pads the current column to 20.
 * Per-column exceptions are swallowed like the reference.
 */
public final class SwoftTablistRuntime {
    private static final int COLUMN_SIZE = 20;

    private static final class View {
        final Player player;
        final String decl;
        final List<UUID> shownUuids = new ArrayList<>();
        Component header = Component.empty();
        Component footer = Component.empty();

        View(Player player, String decl) {
            this.player = player;
            this.decl = decl;
        }
    }

    private record Entry(Component content, PlayerSkin skin) {
    }

    private static final Map<String, TablistModel> DECLS = new ConcurrentHashMap<>();
    private static final Map<UUID, View> VIEWS = new ConcurrentHashMap<>();

    private SwoftTablistRuntime() {
    }

    public static void register(TablistModel model) {
        DECLS.put(model.name(), model);
        if (model.update().kind() == UpdateCadence.Kind.TICKS) {
            MinecraftServer.getSchedulerManager().submitTask(() -> {
                cycleAll(model);
                return TaskSchedule.tick(model.update().ticks());
            }, ExecutionType.TICK_END);
        }
    }

    public static void show(String name, Player player) {
        TablistModel model = lookup(name);
        View previous = VIEWS.get(player.getUuid());
        if (previous != null && !previous.decl.equals(name)) {
            hide(player);
        }
        View view = VIEWS.computeIfAbsent(player.getUuid(), uuid -> new View(player, name));
        cycle(model, view);
    }

    /**
     * Removes the fake entries and resets header/footer to empty
     */
    public static void hide(Player player) {
        View view = VIEWS.remove(player.getUuid());
        if (view == null) {
            return;
        }
        if (!view.shownUuids.isEmpty()) {
            player.sendPacket(new PlayerInfoRemovePacket(List.copyOf(view.shownUuids)));
        }
        player.sendPlayerListHeaderAndFooter(Component.empty(), Component.empty());
    }

    /**
     * One-off header/footer override, in effect until the next update cycle
     */
    public static void setPart(boolean header, Component value, Player player) {
        View view = VIEWS.get(player.getUuid());
        Component other = view != null
                ? (header ? view.footer : view.header)
                : Component.empty();
        Component newHeader = header ? value : other;
        Component newFooter = header ? other : value;
        if (view != null) {
            view.header = newHeader;
            view.footer = newFooter;
        }
        player.sendPlayerListHeaderAndFooter(newHeader, newFooter);
    }

    public static void disconnect(Player player) {
        VIEWS.remove(player.getUuid());
    }

    private static void cycleAll(TablistModel model) {
        for (View view : VIEWS.values()) {
            if (view.decl.equals(model.name()) && view.player.isOnline()) {
                cycle(model, view);
            }
        }
    }

    private static void cycle(TablistModel model, View view) {
        Player player = view.player;
        UiBodyExecutor headerExecutor = new UiBodyExecutor(player, new UiBodyExecutor.Sink() {
        });
        view.header = model.header() != null
                ? (Component) Coercions.toComponent(headerExecutor.evaluateExpression(model.header()))
                : Component.empty();
        view.footer = model.footer() != null
                ? (Component) Coercions.toComponent(headerExecutor.evaluateExpression(model.footer()))
                : Component.empty();
        player.sendPlayerListHeaderAndFooter(view.header, view.footer);

        if (!view.shownUuids.isEmpty()) {
            player.sendPacket(new PlayerInfoRemovePacket(List.copyOf(view.shownUuids)));
            view.shownUuids.clear();
        }

        int slot = 0;
        for (TablistColumnModel column : model.columns()) {
            try {
                slot = sendColumn(model, column, view, slot);
            } catch (Exception e) {
                System.err.println("Tablist '" + model.name() + "' column failed for "
                        + player.getUsername() + ": " + e);
            }
        }
    }

    private static int sendColumn(TablistModel model, TablistColumnModel column, View view, int startSlot) {
        List<Entry> entries = new ArrayList<>();
        PlayerSkin[] fillSkin = new PlayerSkin[1];
        UiBodyExecutor.run(view.player, column.body(), new UiBodyExecutor.Sink() {
            @Override
            public void entry(Component content, PlayerSkin skin) {
                entries.add(new Entry(content, skin));
            }

            @Override
            public void fill(PlayerSkin skin) {
                fillSkin[0] = skin;
            }
        });
        if (fillSkin[0] != null) {
            while (entries.size() < COLUMN_SIZE) {
                entries.add(new Entry(Component.empty(), fillSkin[0]));
            }
        }
        if (entries.size() > COLUMN_SIZE) {
            System.err.println("Tablist '" + model.name() + "' column emitted " + entries.size()
                    + " entries; truncating to " + COLUMN_SIZE);
            entries.subList(COLUMN_SIZE, entries.size()).clear();
        }

        int slot = startSlot;
        for (Entry entry : entries) {
            sendEntry(view, slot++, entry);
        }
        return slot;
    }

    private static void sendEntry(View view, int slot, Entry entry) {
        Player player = view.player;
        UUID uuid = UUID.nameUUIDFromBytes(
                (player.getUuid() + "#tab#" + slot).getBytes(StandardCharsets.UTF_8));
        String fakeName = "tab" + Integer.toString(slot, 36);
        List<PlayerInfoUpdatePacket.Property> properties = entry.skin() != null
                ? List.of(new PlayerInfoUpdatePacket.Property("textures",
                        entry.skin().textures(), entry.skin().signature()))
                : List.of();
        // 1.21.2+ clients sort by DESCENDING list order: emit descending
        // positive values so slot 0 renders first and fakes stay above
        // real players (which use listOrder 0)
        int order = 10_000 - slot;
        player.sendPacket(new PlayerInfoUpdatePacket(
                EnumSet.of(PlayerInfoUpdatePacket.Action.ADD_PLAYER,
                        PlayerInfoUpdatePacket.Action.UPDATE_DISPLAY_NAME,
                        PlayerInfoUpdatePacket.Action.UPDATE_LISTED,
                        PlayerInfoUpdatePacket.Action.UPDATE_LIST_ORDER),
                List.of(new PlayerInfoUpdatePacket.Entry(uuid, fakeName, properties,
                        true, 0, GameMode.CREATIVE, entry.content(), null, order, true))));
        view.shownUuids.add(uuid);
    }

    private static TablistModel lookup(String name) {
        TablistModel model = DECLS.get(name);
        if (model == null) {
            throw new ScriptError("unknown tablist '" + name + "'");
        }
        return model;
    }
}
