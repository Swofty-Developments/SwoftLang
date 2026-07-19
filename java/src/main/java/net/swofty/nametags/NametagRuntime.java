package net.swofty.nametags;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.NamedTextColor;
import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Player;
import net.minestom.server.event.player.PlayerDisconnectEvent;
import net.minestom.server.event.player.PlayerSpawnEvent;
import net.minestom.server.color.TeamColor;
import net.minestom.server.network.packet.server.play.TeamsPacket;
import net.swofty.ScriptError;
import net.swofty.TextFormat;
import net.swofty.items.ItemLoreBuilder;

/**
 * Per-viewer nametags (design 5C / nametags-packets spec Part A): hand-built
 * "ZZZZZ"+username single-member TeamsPacket sends, one per (target,
 * viewer). Client team registries are per-connection, so different viewers
 * can see different prefixes for the same player; re-creating a team is a
 * clean overwrite, so every update is a full CreateTeamAction. Views are
 * re-sent to joining players via a PlayerSpawnEvent listener, and state is
 * dropped (plus RemoveTeamAction hygiene) on target disconnect.
 */
public final class NametagRuntime {
    /** One effective nametag view of a target. */
    public record View(String prefix, String suffix, NamedTextColor color) {
        static final View EMPTY = new View("", "", null);
    }

    private static final class TargetState {
        volatile View defaultView = View.EMPTY;
        final Map<UUID, View> overrides = new ConcurrentHashMap<>();
    }

    public enum Part {
        TEXT, PREFIX, SUFFIX, COLOR
    }

    private static final Map<UUID, TargetState> STATES = new ConcurrentHashMap<>();
    private static boolean initialized = false;

    private NametagRuntime() {
    }

    public static synchronized void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        var handler = MinecraftServer.getGlobalEventHandler();
        // Joining viewer: replay every target's effective view to them;
        // joining target: replay their view to everyone already online.
        handler.addListener(PlayerSpawnEvent.class, event -> {
            Player joined = event.getPlayer();
            for (Player target : MinecraftServer.getConnectionManager().getOnlinePlayers()) {
                TargetState state = STATES.get(target.getUuid());
                if (state != null) {
                    joined.sendPacket(buildPacket(target, effectiveView(state, joined)));
                }
            }
            TargetState ownState = STATES.get(joined.getUuid());
            if (ownState != null) {
                for (Player viewer : MinecraftServer.getConnectionManager().getOnlinePlayers()) {
                    viewer.sendPacket(buildPacket(joined, effectiveView(ownState, viewer)));
                }
            }
        });
        handler.addListener(PlayerDisconnectEvent.class, event -> {
            Player gone = event.getPlayer();
            if (STATES.remove(gone.getUuid()) != null) {
                TeamsPacket removal = new TeamsPacket(teamName(gone),
                        new TeamsPacket.RemoveTeamAction());
                for (Player viewer : MinecraftServer.getConnectionManager().getOnlinePlayers()) {
                    viewer.sendPacket(removal);
                }
            }
            // viewer-side hygiene: drop overrides this player held on others
            for (TargetState state : STATES.values()) {
                state.overrides.remove(gone.getUuid());
            }
        });
    }

    /**
     * set nametag [prefix|suffix|color] of target to value [for viewer].
     * TEXT is the whole-tag form: it becomes the prefix with the suffix
     * cleared (the username itself always renders; teams cannot replace
     * it). viewer == null means the default view seen by everyone without
     * an override.
     */
    public static void set(Player target, Part part, String value, Player viewer) {
        TargetState state = STATES.computeIfAbsent(target.getUuid(), uuid -> new TargetState());
        if (viewer == null) {
            state.defaultView = apply(state.defaultView, part, value);
            broadcast(target, state);
        } else {
            View base = state.overrides.getOrDefault(viewer.getUuid(), state.defaultView);
            View next = apply(base, part, value);
            state.overrides.put(viewer.getUuid(), next);
            viewer.sendPacket(buildPacket(target, next));
        }
    }

    /**
     * reset nametag of target [for viewer]: drop the per-viewer override
     * (falling back to the default view), or the entire state when no
     * viewer is given.
     */
    public static void reset(Player target, Player viewer) {
        TargetState state = STATES.get(target.getUuid());
        if (state == null) {
            return;
        }
        if (viewer == null) {
            STATES.remove(target.getUuid());
            TeamsPacket removal = new TeamsPacket(teamName(target),
                    new TeamsPacket.RemoveTeamAction());
            for (Player online : MinecraftServer.getConnectionManager().getOnlinePlayers()) {
                online.sendPacket(removal);
            }
        } else {
            state.overrides.remove(viewer.getUuid());
            viewer.sendPacket(buildPacket(target, state.defaultView));
        }
    }

    private static View apply(View view, Part part, String value) {
        return switch (part) {
            case TEXT -> new View(value, "", view.color());
            case PREFIX -> new View(value, view.suffix(), view.color());
            case SUFFIX -> new View(view.prefix(), value, view.color());
            case COLOR -> new View(view.prefix(), view.suffix(), parseColor(value));
        };
    }

    public static NamedTextColor parseColor(String value) {
        NamedTextColor color = NamedTextColor.NAMES.value(value.toLowerCase().replace(' ', '_'));
        if (color == null) {
            throw new ScriptError("unknown nametag color '" + value
                    + "' (valid: " + String.join(", ", NamedTextColor.NAMES.keys()) + ")");
        }
        return color;
    }

    private static void broadcast(Player target, TargetState state) {
        for (Player viewer : MinecraftServer.getConnectionManager().getOnlinePlayers()) {
            viewer.sendPacket(buildPacket(target, effectiveView(state, viewer)));
        }
    }

    private static View effectiveView(TargetState state, Player viewer) {
        return state.overrides.getOrDefault(viewer.getUuid(), state.defaultView);
    }

    static String teamName(Player target) {
        return "ZZZZZ" + target.getUsername();
    }

    /**
     * The wire form: single-member CreateTeamAction with friendly-fire flag
     * 0x01, ALWAYS visibility/collision, exactly like the SkyBlock repo's
     * ActionPlayerRemoveTab pattern.
     */
    public static TeamsPacket buildPacket(Player target, View view) {
        return buildPacket(target.getUsername(), view);
    }

    public static TeamsPacket buildPacket(String username, View view) {
        Component prefix = component(view.prefix());
        Component suffix = component(view.suffix());
        // CreateTeamAction now wraps a TeamsPacket.Settings record; the color
        // field is a TeamColor enum rather than a NamedTextColor.
        TeamsPacket.Settings settings = new TeamsPacket.Settings(
                prefix,
                prefix,
                suffix,
                TeamsPacket.NameTagVisibility.ALWAYS,
                TeamsPacket.CollisionRule.ALWAYS,
                toTeamColor(view.color()),
                (byte) 0x01);
        return new TeamsPacket("ZZZZZ" + username,
                new TeamsPacket.CreateTeamAction(settings, List.of(username)));
    }

    /** Map a NamedTextColor onto the wire TeamColor enum (same 16 names). */
    private static TeamColor toTeamColor(NamedTextColor color) {
        if (color == null) {
            return TeamColor.WHITE;
        }
        try {
            return TeamColor.valueOf(color.toString().toUpperCase(java.util.Locale.ROOT));
        } catch (IllegalArgumentException e) {
            return TeamColor.WHITE;
        }
    }

    private static Component component(String text) {
        if (text == null || text.isEmpty()) {
            return Component.empty();
        }
        return ItemLoreBuilder.isMiniMessage(text)
                ? TextFormat.component(text)
                : Component.text(text.replace("&", "§"));
    }
}
