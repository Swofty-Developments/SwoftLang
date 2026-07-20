package net.swofty.harness;

import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.EntityType;
import net.minestom.server.entity.LivingEntity;
import net.minestom.server.entity.Player;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.block.Block;
import net.minestom.server.network.packet.server.SendablePacket;
import net.minestom.server.network.player.GameProfile;
import net.minestom.server.network.player.PlayerConnection;
import net.swofty.ASTExecutor;
import net.swofty.InstanceRegistry;
import net.swofty.blocks.BlockValue;
import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.nativebridge.execution.commands.blocks.PlaceBlockStatement;
import net.swofty.nativebridge.execution.commands.blocks.RemoveBlockStatement;
import net.swofty.nativebridge.execution.commands.tasks.TaskCancelStatement;
import net.swofty.nativebridge.execution.commands.tasks.TaskSetStatement;
import net.swofty.nativebridge.execution.expressions.ScheduleExpression;
import net.swofty.nativebridge.execution.expressions.StringLiteral;
import net.swofty.nativebridge.execution.expressions.TaskRunningExpression;
import net.swofty.nativebridge.execution.expressions.VariableReference;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.props.PropertyTables;
import net.swofty.runtime.ExecutionContext;
import net.swofty.sched.ScheduleHandle;
import net.swofty.sched.ScheduleRuntime;
import net.swofty.tasks.TaskRegistry;

/**
 * --tasks-smoke: end-to-end proofs for the W-tasks per-object task registry
 * ({@code <obj>.tasks.<id>}). First loads the compiled object_tasks.expected.json
 * through {@link SwoftJsonLoader} to prove every new statement/expression kind
 * (task_set / task_cancel / place / remove_block / task_running) builds with no
 * "Unknown statement kind". Then boots a headless MinecraftServer and drives the
 * real statement + registry + schedule paths to assert: a task fires, is_running
 * flips, cancel stops it, independent ids and same-id-across-owners never clash,
 * re-assigning an id cancels the old task, a task auto-cancels when its entity
 * owner is removed, and a block-position task auto-cancels on remove/replace.
 */
public final class TasksSmoke {

    private TasksSmoke() {
    }

    private static int failures = 0;

    private static void check(String label, boolean ok, Object detail) {
        if (ok) {
            System.out.println("  ok   " + label);
        } else {
            failures++;
            System.out.println("  FAIL " + label + "  -> " + detail);
        }
    }

    /** Spin-wait up to timeoutMs for cond; returns whether it became true. */
    private static boolean waitFor(java.util.function.BooleanSupplier cond, long timeoutMs) {
        long deadline = System.currentTimeMillis() + timeoutMs;
        while (System.currentTimeMillis() < deadline) {
            if (cond.getAsBoolean()) {
                return true;
            }
            try {
                Thread.sleep(20);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return false;
            }
        }
        return cond.getAsBoolean();
    }

    private static void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private static ExecutionContext ctx;
    private static Map<String, Object> vars;

    private static Expression ref(String v) {
        return new VariableReference(v);
    }

    /** A schedule body that bumps a counter every fire (an observable tick). */
    private static ExecuteBlock counting(AtomicInteger counter) {
        ExecuteBlock body = new ExecuteBlock();
        body.addStatement(new CountingStatement(counter));
        return body;
    }

    /** every-N-ticks counting schedule expression (serverless: ~50ms/tick). */
    private static ScheduleExpression everyTicks(long n, AtomicInteger counter) {
        return new ScheduleExpression(0, n, counting(counter));
    }

    public static int run(String jsonPath) throws Exception {
        // (0) loader coverage: build every W-tasks node from the compiled AST.
        loaderCoverage(jsonPath);

        MinecraftServer.init();
        PropertyTables.ensureRegistered();
        TaskRegistry.init();
        TaskRegistry.clearAll();

        InstanceContainer instance = MinecraftServer.getInstanceManager()
                .createInstanceContainer();
        instance.setGenerator(unit -> unit.modifier().fillHeight(0, 40, Block.STONE));
        instance.loadChunk(0, 0).join();
        InstanceRegistry.register("world", instance);

        vars = new HashMap<>();
        ctx = new ASTExecutor(
                MinecraftServer.getCommandManager().getConsoleSender(), vars).context();

        playerLifecycle(instance);
        independentIds(instance);
        sameIdAcrossOwners(instance);
        reassignCancelsOld(instance);
        mobAutoCancel(instance);
        blockTasks(instance);

        System.out.println(failures == 0
                ? "[tasks-smoke] all checks passed"
                : "[tasks-smoke] " + failures + " check(s) FAILED");
        return failures == 0 ? 0 : 1;
    }

    /** (0) Load object_tasks.expected.json — proves loader statement coverage. */
    private static void loaderCoverage(String jsonPath) throws Exception {
        System.out.println("[loader coverage]");
        try {
            ParsedScript parsed = SwoftJsonLoader.load(Files.readString(Path.of(jsonPath)));
            check("object_tasks.json loads (no Unknown statement kind)",
                    parsed != null && !parsed.events().isEmpty(), parsed);
        } catch (Exception e) {
            check("object_tasks.json loads (no Unknown statement kind)", false, e.getMessage());
            throw e;
        }
    }

    private static Player fakePlayer(InstanceContainer instance, String name) {
        Player p = new Player(new FakeConnection(), new GameProfile(UUID.randomUUID(), name));
        p.setInstance(instance, new Pos(0, 42, 0)).join();
        return p;
    }

    /** Start on a player, observe a fire, is_running true, cancel -> stops. */
    private static void playerLifecycle(InstanceContainer instance) {
        System.out.println("[player: start / tick / is-running / cancel]");
        Player p = fakePlayer(instance, "Regen");
        vars.put("p", p);
        AtomicInteger fires = new AtomicInteger();

        // set p.tasks.regen to schedule every 2 ticks { <count> }
        new TaskSetStatement(ref("p"), "regen", everyTicks(2, fires)).execute(ctx);

        Object running = new TaskRunningExpression(ref("p"), "regen").evaluate(ctx);
        check("p.tasks.regen is running right after set", Boolean.TRUE.equals(running), running);

        boolean fired = waitFor(() -> fires.get() >= 2, 3000);
        check("p.tasks.regen fires (ticks advance the body)", fired, fires.get());

        // the read <obj>.tasks.<id> resolves to the live Schedule handle
        Object handleRead = ctx.evaluate(new net.swofty.nativebridge.execution.expressions
                .PropertyAccessExpression(
                new net.swofty.nativebridge.execution.expressions
                        .PropertyAccessExpression(ref("p"), "tasks"), "regen"));
        check("p.tasks.regen reads the live Schedule handle",
                handleRead instanceof ScheduleHandle, handleRead);

        // cancel p.tasks.regen -> stops firing + is_running false
        new TaskCancelStatement(ref("p"), "regen").execute(ctx);
        sleep(150);
        int afterCancel = fires.get();
        sleep(400);
        check("cancel p.tasks.regen stops further fires",
                fires.get() == afterCancel, afterCancel + " -> " + fires.get());
        Object stillRunning = new TaskRunningExpression(ref("p"), "regen").evaluate(ctx);
        check("p.tasks.regen not running after cancel",
                Boolean.FALSE.equals(stillRunning), stillRunning);

        p.remove();
    }

    /** Two ids on the SAME owner are independent: cancelling one keeps the other. */
    private static void independentIds(InstanceContainer instance) {
        System.out.println("[independent ids on one owner]");
        Player p = fakePlayer(instance, "TwoTasks");
        vars.put("p", p);
        AtomicInteger a = new AtomicInteger();
        AtomicInteger b = new AtomicInteger();
        new TaskSetStatement(ref("p"), "a", everyTicks(2, a)).execute(ctx);
        new TaskSetStatement(ref("p"), "b", everyTicks(2, b)).execute(ctx);
        check("both ids running", TaskRegistry.isRunning(p, "a")
                && TaskRegistry.isRunning(p, "b"), null);

        new TaskCancelStatement(ref("p"), "a").execute(ctx);
        check("cancel a leaves b running",
                !TaskRegistry.isRunning(p, "a") && TaskRegistry.isRunning(p, "b"), null);

        int bAtCancel = b.get();
        boolean bKeepsFiring = waitFor(() -> b.get() > bAtCancel + 1, 2000);
        check("b keeps firing after a is cancelled", bKeepsFiring, b.get());
        new TaskCancelStatement(ref("p"), "b").execute(ctx);
        p.remove();
    }

    /** Same id on two DIFFERENT owners: keyed by owner identity, never clash. */
    private static void sameIdAcrossOwners(InstanceContainer instance) {
        System.out.println("[same id, two owners]");
        Player p1 = fakePlayer(instance, "OwnerOne");
        Player p2 = fakePlayer(instance, "OwnerTwo");
        vars.put("p1", p1);
        vars.put("p2", p2);
        new TaskSetStatement(ref("p1"), "x", everyTicks(2, new AtomicInteger())).execute(ctx);
        new TaskSetStatement(ref("p2"), "x", everyTicks(2, new AtomicInteger())).execute(ctx);
        check("both owners' x running", TaskRegistry.isRunning(p1, "x")
                && TaskRegistry.isRunning(p2, "x"), null);

        new TaskCancelStatement(ref("p1"), "x").execute(ctx);
        check("cancel p1.x does not touch p2.x",
                !TaskRegistry.isRunning(p1, "x") && TaskRegistry.isRunning(p2, "x"), null);
        new TaskCancelStatement(ref("p2"), "x").execute(ctx);
        p1.remove();
        p2.remove();
    }

    /** Re-assigning the same id cancels the previously stored task first. */
    private static void reassignCancelsOld(InstanceContainer instance) {
        System.out.println("[re-assign cancels old]");
        Player p = fakePlayer(instance, "Reassign");
        AtomicInteger first = new AtomicInteger();
        AtomicInteger second = new AtomicInteger();
        ScheduleHandle handleA = ScheduleRuntime.startExpression(0, 2, counting(first),
                ctx.getSender(), new HashMap<>());
        TaskRegistry.set(p, "r", handleA);
        ScheduleHandle handleB = ScheduleRuntime.startExpression(0, 2, counting(second),
                ctx.getSender(), new HashMap<>());
        TaskRegistry.set(p, "r", handleB);

        check("re-assign cancelled the old handle", !handleA.isRunning(), handleA);
        check("re-assign keeps the new handle running", handleB.isRunning(), handleB);
        check("registry now holds the new handle", TaskRegistry.get(p, "r") == handleB,
                TaskRegistry.get(p, "r"));

        int firstAt = first.get();
        sleep(400);
        check("old handle no longer fires after re-assign", first.get() == firstAt,
                firstAt + " -> " + first.get());
        TaskRegistry.cancel(p, "r");
        p.remove();
    }

    /** A task on a mob auto-cancels when the mob is removed (no orphan fires). */
    private static void mobAutoCancel(InstanceContainer instance) {
        System.out.println("[mob auto-cancel on despawn]");
        LivingEntity mob = new LivingEntity(EntityType.IRON_GOLEM);
        mob.setInstance(instance, new Pos(3, 42, 0)).join();
        vars.put("mob", mob);
        AtomicInteger fires = new AtomicInteger();
        // bind through the registry with a handle we keep, so we can prove the
        // schedule itself stops (not just that the bucket was dropped)
        ScheduleHandle handle = ScheduleRuntime.startExpression(0, 2, counting(fires),
                ctx.getSender(), new HashMap<>());
        TaskRegistry.set(mob, "patrol", handle);
        check("mob.tasks.patrol running before despawn",
                TaskRegistry.isRunning(mob, "patrol"), null);
        check("mob.tasks.patrol fires before despawn", waitFor(() -> fires.get() >= 2, 3000),
                fires.get());

        int trackedBefore = TaskRegistry.trackedOwners();
        mob.remove(); // EntityDespawnEvent -> TaskRegistry.cancelEntity

        boolean cancelled = waitFor(() -> !handle.isRunning(), 1500);
        check("despawn auto-cancels the mob task handle", cancelled, handle);
        check("mob.tasks.patrol not running after despawn",
                !TaskRegistry.isRunning(mob, "patrol"), null);
        check("mob owner bucket dropped on despawn",
                TaskRegistry.trackedOwners() < trackedBefore, TaskRegistry.trackedOwners());

        int firesAt = fires.get();
        sleep(400);
        check("no orphan fires after mob despawn", fires.get() == firesAt,
                firesAt + " -> " + fires.get());
    }

    /** place sets the block; a position task auto-cancels on remove/replace. */
    private static void blockTasks(InstanceContainer instance) {
        System.out.println("[block-at-position tasks: place / remove / replace]");
        Pos pos = new Pos(10, 41, 10);
        vars.put("loc", pos);

        // place "minecraft:sea_lantern" at loc -> the block is actually set
        new PlaceBlockStatement(new StringLiteral("minecraft:sea_lantern"), ref("loc"))
                .execute(ctx);
        Block placed = instance.getBlock(pos.blockX(), pos.blockY(), pos.blockZ());
        check("place sets the block", placed.compare(Block.SEA_LANTERN), placed.name());

        // bind a task to block_at(loc): a positioned BlockValue keyed by position
        BlockValue positioned = new BlockValue(placed, instance, pos);
        AtomicInteger pulse = new AtomicInteger();
        ScheduleHandle handle = ScheduleRuntime.startExpression(0, 2, counting(pulse),
                ctx.getSender(), new HashMap<>());
        TaskRegistry.set(positioned, "pulse", handle);
        check("block_at(loc).tasks.pulse running", TaskRegistry.isRunning(positioned, "pulse"),
                null);
        check("block task keyed by position (a fresh BlockValue at loc resolves it)",
                TaskRegistry.isRunning(new BlockValue(placed, instance, pos), "pulse"), null);

        // remove block at loc -> air + every task bound to that position cancelled
        new RemoveBlockStatement(ref("loc")).execute(ctx);
        Block after = instance.getBlock(pos.blockX(), pos.blockY(), pos.blockZ());
        check("remove block sets air", after.compare(Block.AIR), after.name());
        boolean cancelled = waitFor(() -> !handle.isRunning(), 1500);
        check("remove block auto-cancels the position task", cancelled, handle);
        int pulseAt = pulse.get();
        sleep(400);
        check("no orphan fires after block removed", pulse.get() == pulseAt,
                pulseAt + " -> " + pulse.get());

        // replace path: place a different block over a live position task -> cancel
        Pos pos2 = new Pos(11, 41, 11);
        vars.put("loc2", pos2);
        new PlaceBlockStatement(new StringLiteral("minecraft:sea_lantern"), ref("loc2"))
                .execute(ctx);
        BlockValue positioned2 = new BlockValue(
                instance.getBlock(pos2.blockX(), pos2.blockY(), pos2.blockZ()), instance, pos2);
        ScheduleHandle handle2 = ScheduleRuntime.startExpression(0, 2,
                counting(new AtomicInteger()), ctx.getSender(), new HashMap<>());
        TaskRegistry.set(positioned2, "glow", handle2);
        new PlaceBlockStatement(new StringLiteral("minecraft:oak_log"), ref("loc2")).execute(ctx);
        boolean replaced = waitFor(() -> !handle2.isRunning(), 1500);
        check("replacing the block auto-cancels its position task", replaced, handle2);
    }

    /** A schedule-body statement that bumps a counter each fire. */
    private static final class CountingStatement extends AbstractAstNode implements Statement {
        private final AtomicInteger counter;

        CountingStatement(AtomicInteger counter) {
            this.counter = counter;
        }

        @Override
        public void execute(ExecutionContext context) {
            counter.incrementAndGet();
        }
    }

    /** Minimal offline connection so we can spawn real Players headless. */
    private static final class FakeConnection extends PlayerConnection {
        @Override
        public void sendPacket(SendablePacket packet) {
        }

        @Override
        public SocketAddress getRemoteAddress() {
            return new InetSocketAddress(0);
        }
    }
}
