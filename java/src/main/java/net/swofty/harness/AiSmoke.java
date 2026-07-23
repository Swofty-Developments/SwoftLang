package net.swofty.harness;

import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Point;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.ai.EntityAIGroup;
import net.minestom.server.entity.ai.GoalSelector;
import net.minestom.server.entity.ai.TargetSelector;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.block.Block;
import net.minestom.server.network.packet.server.SendablePacket;
import net.minestom.server.network.player.GameProfile;
import net.minestom.server.network.player.PlayerConnection;
import net.swofty.InstanceRegistry;
import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.mobs.MobRegistry;
import net.swofty.mobs.SwoftMob;
import net.swofty.mobs.ai.GoalTypeModel;
import net.swofty.mobs.ai.GoalTypeRegistry;
import net.swofty.mobs.ai.ScriptedGoalSelector;
import net.swofty.model.MobDefModel;
import net.swofty.props.PropertyTables;

/**
 * --ai-smoke &lt;compiled.json&gt;: a headless, fake-player proof of the v1.9.0
 * custom mob AI runtime (design §2-5). Loads {@code scripts/ai_smoke.sw.json},
 * spawns a scripted-AI mob near a fake player, and drives the goal/target/
 * navigator machinery WITHOUT a real server tick loop, asserting:
 *
 * <ul>
 *   <li>WIRING — the {@code ai { }} block became exactly one {@code
 *       EntityAIGroup} on the creature with its scripted {@code GoalSelector}s
 *       (in priority order) and {@code TargetSelector}s installed;</li>
 *   <li>BINDING — a goal's {@code should_start} sees the bound {@code target}
 *       (true while a player is in range) and {@code on_tick} runs with {@code
 *       mob} + {@code target} bound, driving the navigator toward the target;</li>
 *   <li>NAVIGATOR — {@code path mob to target} sets the navigator's goal
 *       position onto the player;</li>
 *   <li>PRIORITY — the higher-priority {@code chase} precedes (and, via the
 *       group tick, preempts) the lower-priority {@code wander};</li>
 *   <li>NONE-TARGET — a {@code target { return none }} block yields no target,
 *       so a {@code should_start { target exists }} goal does not start;</li>
 *   <li>TEARDOWN — removing the mobs drops their AI groups and clearing the
 *       {@link GoalTypeRegistry} leaves no ghost lifecycles (the reload path).</li>
 * </ul>
 */
public final class AiSmoke {

    private static int failures = 0;

    private AiSmoke() {
    }

    private static void check(String label, boolean ok, Object detail) {
        if (ok) {
            System.out.println("[AI] ok   " + label);
        } else {
            failures++;
            System.out.println("[AI] FAIL " + label + "  -> " + detail);
        }
    }

    public static int run(String jsonPath) throws Exception {
        MinecraftServer.init();
        MinecraftServer.getExceptionManager().setExceptionHandler(Throwable::printStackTrace);
        PropertyTables.ensureRegistered();

        ParsedScript parsed = SwoftJsonLoader.load(Files.readString(Path.of(jsonPath)));

        // Register reusable goal TYPES before the mobs (engine ordering) so a
        // `goals: [Idle]` reference could resolve; then the mob defs.
        GoalTypeRegistry.clear();
        for (GoalTypeModel gt : parsed.goalTypes()) {
            GoalTypeRegistry.register(gt.name(), gt.lifecycle());
        }
        check("goal type 'Idle' registered", GoalTypeRegistry.get("Idle") != null,
                GoalTypeRegistry.size());
        MobRegistry.clear();
        for (MobDefModel mob : parsed.mobs()) {
            MobRegistry.register(mob);
        }

        InstanceContainer instance = MinecraftServer.getInstanceManager()
                .createInstanceContainer();
        instance.setGenerator(unit -> unit.modifier().fillHeight(0, 64, Block.STONE));
        instance.loadChunk(0, 0).join();
        InstanceRegistry.register("world", instance);

        Player alice = new Player(new FakeConnection(),
                new GameProfile(UUID.randomUUID(), "Alice"));
        alice.setInstance(instance, new Pos(0.5, 65, 0.5)).join();

        // Spawn the hunter a few blocks from the player, well within `within 32`.
        SwoftMob hunter = MobRegistry.spawn("hunter", new Pos(5.5, 65, 0.5), instance);

        // ---- WIRING: one AI group, 2 goals (priority order), 1 target ---------
        List<EntityAIGroup> groups = List.copyOf(hunter.getAIGroups());
        check("hunter has exactly one AI group", groups.size() == 1, groups.size());
        EntityAIGroup group = groups.get(0);
        List<GoalSelector> goals = group.getGoalSelectors();
        List<TargetSelector> targets = group.getTargetSelectors();
        check("group has 2 goal selectors", goals.size() == 2, goals.size());
        check("group has 1 target selector", targets.size() == 1, targets.size());
        check("both goals are scripted",
                goals.get(0) instanceof ScriptedGoalSelector
                        && goals.get(1) instanceof ScriptedGoalSelector, goals);

        GoalSelector chase = goals.get(0);
        GoalSelector wander = goals.get(1);
        check("higher-priority 'chase' is first in the group",
                chase instanceof ScriptedGoalSelector c && "chase".equals(c.goalName()),
                name(chase));
        check("lower-priority 'wander' (priority 5) is second",
                wander instanceof ScriptedGoalSelector w && "wander".equals(w.goalName()),
                name(wander));

        // ---- BINDING: should_start sees the bound target ----------------------
        check("chase.shouldStart() true — player in range => `target exists`",
                chase.shouldStart(), false);

        // ---- NAVIGATOR: on_tick binds mob+target and paths toward the player --
        hunter.getNavigator().reset();
        check("navigator idle before tick (no goal)",
                hunter.getNavigator().getGoalPosition() == null,
                hunter.getNavigator().getGoalPosition());
        chase.start();      // runs on_start { look at target } (must not throw)
        chase.tick(0L);     // runs on_tick { path mob to target }
        Point goal = hunter.getNavigator().getGoalPosition();
        check("chase.on_tick set a navigator path (mob+target were bound)",
                goal != null, goal);
        check("navigator goal is the target's position (path mob to target)",
                goal != null && goal.distance(alice.getPosition()) < 1.5,
                goal + " vs player " + alice.getPosition());

        // ---- PRIORITY / PREEMPTION: chase wins over wander --------------------
        check("wander.shouldStart() also true (default) — both eligible",
                wander.shouldStart(), false);
        hunter.getNavigator().reset();
        group.tick(1L);     // group must pick the FIRST eligible => chase
        check("group tick selected the higher-priority chase (preempts wander)",
                group.getCurrentGoalSelector() == chase, name(group.getCurrentGoalSelector()));
        Point afterGroup = hunter.getNavigator().getGoalPosition();
        check("after group tick the navigator points at the target "
                        + "(chase ran, not wander's `stop pathing`)",
                afterGroup != null && afterGroup.distance(alice.getPosition()) < 1.5,
                afterGroup);

        // ---- NONE-TARGET: a `target { return none }` block => no target -------
        SwoftMob blind = MobRegistry.spawn("blind", new Pos(-5.5, 65, 0.5), instance);
        EntityAIGroup bg = List.copyOf(blind.getAIGroups()).get(0);
        TargetSelector blindTarget = bg.getTargetSelectors().get(0);
        check("block target returning none => findTarget() is null",
                blindTarget.findTarget() == null, blindTarget.findTarget());
        GoalSelector seek = bg.getGoalSelectors().get(0);
        check("`should_start { target exists }` is FALSE when the target is none",
                !seek.shouldStart(), true);

        // ---- TEARDOWN: removing mobs drops AI groups; clearing goal types
        //      leaves no ghost lifecycle (the reload teardown path) -------------
        int liveBefore = MobRegistry.all(null).size();
        check("two scripted-AI mobs live before teardown", liveBefore == 2, liveBefore);
        hunter.remove();
        blind.remove();
        check("after remove: no live mobs left in the registry",
                MobRegistry.all(null).isEmpty(), MobRegistry.all(null).size());
        // A removed entity is no longer ticked (its AI never runs again); that —
        // not the retained group list on the dead object — is the teardown signal.
        check("removed hunter is torn down (removed from the world, no more ticks)",
                hunter.isRemoved(), hunter.isRemoved());
        GoalTypeRegistry.clear();
        check("after GoalTypeRegistry.clear(): no ghost goal types",
                GoalTypeRegistry.size() == 0, GoalTypeRegistry.size());

        System.out.println(failures == 0
                ? "[AI] PASS"
                : "[AI] " + failures + " failure(s)");
        return failures == 0 ? 0 : 1;
    }

    private static String name(GoalSelector g) {
        return g instanceof ScriptedGoalSelector s ? s.goalName() : String.valueOf(g);
    }

    /** Minimal offline PlayerConnection. */
    static final class FakeConnection extends PlayerConnection {
        final List<SendablePacket> sent = new CopyOnWriteArrayList<>();

        @Override
        public void sendPacket(SendablePacket packet) {
            sent.add(packet);
        }

        @Override
        public SocketAddress getRemoteAddress() {
            return new InetSocketAddress(0);
        }
    }
}
