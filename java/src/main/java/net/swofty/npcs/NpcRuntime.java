package net.swofty.npcs;

import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.EntityType;
import net.minestom.server.entity.GameMode;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.PlayerHand;
import net.minestom.server.entity.PlayerSkin;
import net.minestom.server.event.entity.EntityAttackEvent;
import net.minestom.server.event.player.PlayerDisconnectEvent;
import net.minestom.server.event.player.PlayerEntityInteractEvent;
import net.minestom.server.instance.Instance;
import net.minestom.server.network.packet.server.play.PlayerInfoRemovePacket;
import net.minestom.server.network.packet.server.play.PlayerInfoUpdatePacket;
import net.minestom.server.network.packet.server.play.TeamsPacket;
import net.minestom.server.timer.ExecutionType;
import net.minestom.server.timer.Task;
import net.minestom.server.timer.TaskSchedule;
import net.swofty.ASTExecutor;
import net.swofty.InstanceRegistry;
import net.swofty.ScriptError;
import net.swofty.async.AsyncRuntime;
import net.swofty.async.TickDispatch;
import net.swofty.model.NpcModel;
import net.swofty.model.NpcModel.NpcSkinModel;
import net.swofty.nametags.NametagRuntime;
import net.swofty.props.Coercions;
import net.swofty.skins.SkinFetcher;

/**
 * First-class {@code npc "name" { ... }} runtime (design 6C). Supersedes the
 * hand-rolled {@code addons/npcs.sw} closure-chain store.
 *
 * <p>Each NPC is a fake {@link Entity} of {@link EntityType#PLAYER} — never a
 * real connection, so it is invisible to {@code ConnectionManager} and the
 * {@code /tp <player>} suggestion callback (the runtime-pass tablist
 * fake-player scoping fix already answers completions from
 * {@code getOnlinePlayers()} only, so NPCs never tab-complete). Per new
 * viewer the entity injects a {@link PlayerInfoUpdatePacket} ADD carrying the
 * skin texture property (so the skin resolves) plus a per-viewer name
 * {@link TeamsPacket}, then lets Minestom send the spawn packet, then removes
 * the player-list entry ~2 ticks later ({@link PlayerInfoRemovePacket}) so the
 * NPC shows in the world but not the tab list.
 *
 * <p>{@code look_at_players} runs a scheduler loop that rotates the head
 * (yaw/pitch) toward the nearest player with {@link Math#atan2} in Java — no
 * hand-rolled script trig. Right-clicks ({@link PlayerEntityInteractEvent})
 * dispatch {@code on_click(player)} and left-clicks ({@link EntityAttackEvent})
 * dispatch {@code on_left_click(player)} through {@link ASTExecutor} with
 * {@code player} bound. Cleanup runs on {@code remove}, on disconnect (handled
 * by Minestom's viewer teardown), and via {@link #teardown()} for hot-reload
 * (#58).
 */
public final class NpcRuntime {
    /** Approx. player eye height, for look-at pitch/yaw math. */
    private static final double EYE_HEIGHT = 1.62;
    private static final int LOOK_PERIOD_TICKS = 2;
    private static final int LIST_LINGER_TICKS = 2;

    private static final Map<String, Npc> NPCS = new ConcurrentHashMap<>();
    private static final Map<String, Task> LOOK_TASKS = new ConcurrentHashMap<>();
    /** Entity id -> NPC, for O(1) interact dispatch. */
    private static final Map<Integer, Npc> BY_ENTITY_ID = new ConcurrentHashMap<>();

    private static volatile boolean initialized = false;

    private NpcRuntime() {
    }

    // ------------------------------------------------------------------
    // one-time listener wiring
    // ------------------------------------------------------------------

    public static synchronized void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        var handler = MinecraftServer.getGlobalEventHandler();

        // Right-click an NPC -> on_click(player). Guard to the main hand so a
        // single physical click fires exactly once.
        handler.addListener(PlayerEntityInteractEvent.class, event -> {
            if (event.getHand() != PlayerHand.MAIN) {
                return;
            }
            Npc npc = BY_ENTITY_ID.get(event.getTarget().getEntityId());
            if (npc != null) {
                dispatch(npc, npc.model.onClick(), event.getPlayer());
            }
        });

        // Left-click (attack) an NPC -> on_left_click(player).
        handler.addListener(EntityAttackEvent.class, event -> {
            if (!(event.getEntity() instanceof Player player)) {
                return;
            }
            Npc npc = BY_ENTITY_ID.get(event.getTarget().getEntityId());
            if (npc != null) {
                dispatch(npc, npc.model.onLeftClick(), player);
            }
        });

        // Disconnect: Minestom auto-removes the leaving player as a viewer and
        // calls updateOldViewer (which sends the tablist/team removals), so no
        // server-side per-viewer state needs clearing here. Present for parity.
        handler.addListener(PlayerDisconnectEvent.class, event -> disconnect(event.getPlayer()));
    }

    // ------------------------------------------------------------------
    // registration + declared spawn
    // ------------------------------------------------------------------

    /** Spawn the declared NPC at engine init (design: spawn is implicit). */
    public static void register(NpcModel model) {
        init();
        Npc npc = new Npc(model);
        NPCS.put(model.name(), npc);

        ASTExecutor executor = new ASTExecutor(handlerSender(), new HashMap<>());
        npc.pos = (Pos) Coercions.toPos(executor.evaluateExpression(model.location()));
        npc.instance = instanceFor(npc.pos);

        // Resolve the skin. A texture pair is immediate; a username needs an
        // async Mojang fetch, so spawn skin-less now and refresh when it lands.
        if (model.skin() != null && model.skin().kind() == NpcSkinModel.Kind.TEXTURE) {
            String tex = String.valueOf(Coercions.toStringValue(
                    executor.evaluateExpression(model.skin().texture())));
            String sig = model.skin().signature() == null ? null
                    : String.valueOf(Coercions.toStringValue(
                            executor.evaluateExpression(model.skin().signature())));
            npc.skin = new PlayerSkin(tex, sig);
        }

        spawn(npc);

        if (model.skin() != null && model.skin().kind() == NpcSkinModel.Kind.USERNAME) {
            String username = String.valueOf(Coercions.toStringValue(
                    executor.evaluateExpression(model.skin().username())));
            fetchSkinAsync(npc, username);
        }
        if (model.lookAtPlayers()) {
            startLookTask(npc);
        }
    }

    private static void spawn(Npc npc) {
        BY_ENTITY_ID.put(npc.entity.getEntityId(), npc);
        Instance instance = npc.instance;
        Pos pos = npc.pos;
        TickDispatch.call(() -> {
            npc.entity.setInstance(instance, pos);
            return null;
        });
    }

    // ------------------------------------------------------------------
    // statements: set skin / name / location, remove
    // ------------------------------------------------------------------

    /** {@code set npc "name" skin to <username|skin>}. */
    public static void setSkin(String name, Object value) {
        Npc npc = require(name);
        if (value instanceof PlayerSkin skin) {
            npc.skin = skin;
            refreshViewers(npc);
        } else {
            fetchSkinAsync(npc, String.valueOf(Coercions.toStringValue(value)));
        }
    }

    /** {@code set npc "name" name to <expr>} — resend the per-viewer team. */
    public static void setName(String name, Object value) {
        Npc npc = require(name);
        npc.staticName = String.valueOf(Coercions.toStringValue(value));
        for (Player viewer : Set.copyOf(npc.entity.getViewers())) {
            viewer.sendPacket(npc.namePacket(viewer));
        }
    }

    /** {@code set npc "name" location to <location>} / teleport npc. */
    public static void setLocation(String name, Object location) {
        Npc npc = require(name);
        Pos pos = (Pos) Coercions.toPos(location);
        npc.pos = pos;
        TickDispatch.call(() -> npc.entity.teleport(pos));
    }

    /** {@code remove npc "name"} — despawn and drop all state. */
    public static void remove(String name) {
        Npc npc = NPCS.remove(name);
        Task look = LOOK_TASKS.remove(name);
        if (look != null) {
            look.cancel();
        }
        if (npc != null) {
            destroy(npc);
        }
    }

    // ------------------------------------------------------------------
    // lifecycle: disconnect + hot-reload teardown (#58)
    // ------------------------------------------------------------------

    public static void disconnect(Player player) {
        // Minestom removes the leaving player from every entity's viewer set
        // and fires updateOldViewer, which sends the tablist + team removals.
        // Nothing further to clean server-side.
    }

    /** Tear down every NPC (hot-reload #58): cancel loops, kill entities. */
    public static void teardown() {
        for (Task task : LOOK_TASKS.values()) {
            task.cancel();
        }
        LOOK_TASKS.clear();
        for (Npc npc : NPCS.values()) {
            destroy(npc);
        }
        NPCS.clear();
        BY_ENTITY_ID.clear();
    }

    // ------------------------------------------------------------------
    // skin + viewer refresh
    // ------------------------------------------------------------------

    private static void fetchSkinAsync(Npc npc, String username) {
        AsyncRuntime.start("npc-skin:" + npc.model.name(), () -> {
            PlayerSkin skin = SkinFetcher.fetch(username);
            if (skin != null) {
                npc.skin = skin;
                refreshViewers(npc);
            } else {
                System.err.println("NPC '" + npc.model.name()
                        + "': could not fetch skin for username '" + username + "'");
            }
        });
    }

    /**
     * Re-send the entity to every current viewer so a changed skin (carried
     * in the per-viewer ADD packet) takes effect: removeViewer fires
     * updateOldViewer (destroy), addViewer fires updateNewViewer (fresh ADD +
     * spawn with the new texture property).
     */
    private static void refreshViewers(Npc npc) {
        TickDispatch.call(() -> {
            for (Player viewer : Set.copyOf(npc.entity.getViewers())) {
                npc.entity.removeViewer(viewer);
                npc.entity.addViewer(viewer);
            }
            return null;
        });
    }

    // ------------------------------------------------------------------
    // look-at-players loop (Math.atan2 in Java)
    // ------------------------------------------------------------------

    private static void startLookTask(Npc npc) {
        Task task = MinecraftServer.getSchedulerManager().submitTask(() -> {
            try {
                lookAtNearest(npc);
            } catch (Exception e) {
                System.err.println("NPC '" + npc.model.name() + "' look failed: " + e);
            }
            return TaskSchedule.tick(LOOK_PERIOD_TICKS);
        }, ExecutionType.TICK_END);
        LOOK_TASKS.put(npc.model.name(), task);
    }

    private static void lookAtNearest(Npc npc) {
        Instance instance = npc.entity.getInstance();
        if (instance == null) {
            return;
        }
        Pos base = npc.entity.getPosition();
        Player nearest = null;
        double best = Double.MAX_VALUE;
        for (Player player : instance.getPlayers()) {
            double d = player.getPosition().distanceSquared(base);
            if (d < best) {
                best = d;
                nearest = player;
            }
        }
        if (nearest == null) {
            return;
        }
        float[] view = viewToward(base, nearest.getPosition());
        npc.entity.setView(view[0], view[1]);
    }

    /**
     * The Minecraft yaw/pitch that makes an entity at {@code base} look at the
     * eyes of a target at {@code target}. Yaw is measured clockwise from +Z;
     * pitch is downward-positive. Real runtime trig (Math.atan2), no
     * hand-rolled script math.
     */
    private static float[] viewToward(Pos base, Pos target) {
        double dx = target.x() - base.x();
        double dy = (target.y() + EYE_HEIGHT) - (base.y() + EYE_HEIGHT);
        double dz = target.z() - base.z();
        double distXz = Math.sqrt(dx * dx + dz * dz);
        float yaw = (float) Math.toDegrees(Math.atan2(-dx, dz));
        float pitch = (float) (-Math.toDegrees(Math.atan2(dy, distXz)));
        return new float[] { yaw, pitch };
    }

    // ------------------------------------------------------------------
    // click dispatch
    // ------------------------------------------------------------------

    private static void dispatch(Npc npc, net.swofty.nativebridge.representation.ExecuteBlock body,
            Player player) {
        if (body == null || body.isEmpty()) {
            return;
        }
        Map<String, Object> vars = new HashMap<>();
        vars.put("player", player);
        try {
            new ASTExecutor(player, vars).execute(body);
        } catch (Exception e) {
            System.err.println("NPC '" + npc.model.name() + "' click handler failed: "
                    + e.getMessage());
        }
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    private static void destroy(Npc npc) {
        BY_ENTITY_ID.remove(npc.entity.getEntityId());
        UUID id = npc.entityUuid;
        String team = npc.teamName();
        TickDispatch.call(() -> {
            for (Player viewer : Set.copyOf(npc.entity.getViewers())) {
                viewer.sendPacket(new PlayerInfoRemovePacket(id));
                viewer.sendPacket(new TeamsPacket(team, new TeamsPacket.RemoveTeamAction()));
            }
            npc.entity.remove();
            return null;
        });
    }

    private static Npc require(String name) {
        Npc npc = NPCS.get(name);
        if (npc == null) {
            throw new ScriptError("unknown npc '" + name + "'");
        }
        return npc;
    }

    // ------------------------------------------------------------------
    // test hooks (harness only)
    // ------------------------------------------------------------------

    /** The fake entity backing an NPC, or null when unknown. */
    public static Entity entity(String name) {
        Npc npc = NPCS.get(name);
        return npc == null ? null : npc.entity;
    }

    /** The resolved skin of an NPC (may be null before an async fetch lands). */
    public static PlayerSkin skinOf(String name) {
        Npc npc = NPCS.get(name);
        return npc == null ? null : npc.skin;
    }

    /** Run one look-at-nearest iteration now (bypasses the 2-tick scheduler). */
    public static void lookNow(String name) {
        Npc npc = NPCS.get(name);
        if (npc != null) {
            lookAtNearest(npc);
        }
    }

    /**
     * Rotate the NPC's head toward an explicit target position now, through the
     * same {@link #viewToward} atan2 math + {@code setView} the look loop uses.
     * (Harness hook: exercises the real head-tracking path without depending on
     * the headless instance's player-tracking set.)
     */
    public static void lookAt(String name, Object targetPos) {
        Npc npc = NPCS.get(name);
        if (npc == null) {
            return;
        }
        Pos target = (Pos) Coercions.toPos(targetPos);
        float[] view = viewToward(npc.entity.getPosition(), target);
        npc.entity.setView(view[0], view[1]);
    }

    /** True when an NPC's look-at scheduler task is live. */
    public static boolean hasLookTask(String name) {
        return LOOK_TASKS.containsKey(name);
    }

    private static Instance instanceFor(Pos pos) {
        Instance world = InstanceRegistry.get("world");
        if (world != null) {
            return world;
        }
        for (Instance instance : MinecraftServer.getInstanceManager().getInstances()) {
            return instance;
        }
        throw new ScriptError("npc: no world to spawn into");
    }

    private static CommandSender handlerSender() {
        try {
            return MinecraftServer.getCommandManager().getConsoleSender();
        } catch (Throwable t) {
            return null;
        }
    }

    // ------------------------------------------------------------------
    // one NPC
    // ------------------------------------------------------------------

    private static final class Npc {
        final NpcModel model;
        final FakePlayer entity;
        final UUID entityUuid;
        final String fakeUsername;
        volatile Pos pos;
        volatile Instance instance;
        volatile PlayerSkin skin;
        /** Non-per-viewer name override from {@code set npc name}, if any. */
        volatile String staticName;

        Npc(NpcModel model) {
            this.model = model;
            this.entityUuid = UUID.nameUUIDFromBytes(
                    ("npc#" + model.name()).getBytes(StandardCharsets.UTF_8));
            this.fakeUsername = sanitizeUsername(model.name());
            this.entity = new FakePlayer(this);
        }

        /** The (per-viewer) name string in MiniMessage source form. */
        String nameFor(Player viewer) {
            if (staticName != null) {
                return staticName;
            }
            if (model.displayName() == null) {
                return null;
            }
            Map<String, Object> vars = new HashMap<>();
            vars.put("player", viewer);
            return new ASTExecutor(viewer, vars).evaluateStringExpression(model.displayName());
        }

        /** A single-member team whose prefix carries the styled overhead name. */
        TeamsPacket namePacket(Player viewer) {
            String rendered = nameFor(viewer);
            NametagRuntime.View view = new NametagRuntime.View(
                    rendered == null ? "" : rendered, "", null);
            return NametagRuntime.buildPacket(fakeUsername, view);
        }

        /** The single-member team name for this NPC's fake username. */
        String teamName() {
            return "ZZZZZ" + fakeUsername;
        }

        List<PlayerInfoUpdatePacket.Property> properties() {
            return skin != null
                    ? List.of(new PlayerInfoUpdatePacket.Property(
                            "textures", skin.textures(), skin.signature()))
                    : List.of();
        }
    }

    /**
     * A player-typed entity whose viewer hooks inject the fake-player
     * PlayerInfo entry (so the skin resolves) around Minestom's spawn packet,
     * then strip it from the tab list a couple ticks later.
     */
    private static final class FakePlayer extends Entity {
        private final Npc npc;

        FakePlayer(Npc npc) {
            super(EntityType.PLAYER, npc.entityUuid);
            this.npc = npc;
            setNoGravity(true);
            // viewable:false => hidden until an explicit `show npc ... to ...`.
            setAutoViewable(npc.model.viewable());
        }

        @Override
        public void updateNewViewer(Player player) {
            // 1) ADD to the player-info registry (unlisted -> never shown in the
            //    tab list) carrying the skin texture property so it resolves.
            player.sendPacket(new PlayerInfoUpdatePacket(
                    PlayerInfoUpdatePacket.Action.ADD_PLAYER,
                    new PlayerInfoUpdatePacket.Entry(npc.entityUuid, npc.fakeUsername,
                            npc.properties(), false, 0, GameMode.SURVIVAL,
                            null, null, 0, false)));
            // 2) per-viewer overhead name via a single-member team.
            player.sendPacket(npc.namePacket(player));
            // 3) Minestom sends the spawn-player-entity packet.
            super.updateNewViewer(player);
            // 4) remove the player-list entry ~2 ticks later; the spawned
            //    entity keeps its cached skin, so it stays in-world only.
            UUID id = npc.entityUuid;
            int[] phase = {0};
            MinecraftServer.getSchedulerManager().submitTask(() -> {
                if (phase[0]++ == 0) {
                    return TaskSchedule.tick(LIST_LINGER_TICKS);
                }
                if (player.isOnline() && getViewers().contains(player)) {
                    player.sendPacket(new PlayerInfoRemovePacket(id));
                }
                return TaskSchedule.stop();
            }, ExecutionType.TICK_END);
        }

        @Override
        public void updateOldViewer(Player player) {
            super.updateOldViewer(player);
            // hygiene: drop the (possibly still-present) list entry + the team.
            player.sendPacket(new PlayerInfoRemovePacket(npc.entityUuid));
            player.sendPacket(new TeamsPacket(npc.teamName(),
                    new TeamsPacket.RemoveTeamAction()));
        }
    }

    /** A valid 1-16 char player-info username derived from the NPC name. */
    private static String sanitizeUsername(String name) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < name.length() && sb.length() < 16; i++) {
            char c = name.charAt(i);
            if (c == '_' || Character.isLetterOrDigit(c)) {
                sb.append(c);
            }
        }
        if (sb.length() == 0) {
            sb.append("npc").append(Integer.toString(Math.abs(name.hashCode()), 36));
            if (sb.length() > 16) {
                sb.setLength(16);
            }
        }
        return sb.toString();
    }
}
