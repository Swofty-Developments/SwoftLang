package net.swofty.sched;

import java.util.Map;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.swofty.ASTExecutor;
import net.swofty.async.AsyncRuntime;
import net.swofty.async.TickClock;
import net.swofty.model.EveryDeclModel;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.runtime.SystemSender;

/**
 * Declarative schedulers (design 6D + scheduler v2): {@code every}-decls
 * started at engine init, {@code schedule} expressions, and {@code repeat N
 * times} statements — all running on AsyncRuntime virtual threads,
 * tick-aligned via TickClock. Bodies are async-colored.
 *
 * <p>Scheduler v2 adds: a per-fire {@code run} counter bound into the block
 * environment, self-cancellation via the {@code stop} statement (which flips
 * the handle's cancel flag, checked before the next fire and honoured even
 * from a nested {@code async {}} because the handle rides in the captured
 * environment), fixed-count {@code repeat}, and names.
 */
public final class ScheduleRuntime {
    /**
     * Reserved environment key carrying the enclosing schedule's handle so a
     * {@code stop} statement (design v2) can cancel it. Not a valid script
     * identifier, so it never collides with a user variable.
     */
    public static final String HANDLE_KEY = "$schedule";

    private ScheduleRuntime() {
    }

    /** Boot a top-level every-declaration (engine register). */
    public static ScheduleHandle startEvery(EveryDeclModel decl) {
        return start("every " + decl.intervalTicks() + "t", decl.name(),
                decl.delayTicks() > 0 ? decl.delayTicks() : decl.intervalTicks(),
                decl.intervalTicks(), 0, false, decl.body(), handlerSender(), null);
    }

    /**
     * Start a schedule expression: after N ticks, then every M ticks (either
     * may be absent; a pure after-schedule runs once). The body runs
     * closure-style over the captured environment. An optional name registers
     * the handle for cancel-by-name / is_running.
     */
    public static ScheduleHandle startExpression(long afterTicks, long everyTicks,
            String name, ExecuteBlock body, CommandSender sender, Map<String, Object> captured) {
        String description = (afterTicks > 0 ? "after " + afterTicks + "t " : "")
                + (everyTicks > 0 ? "every " + everyTicks + "t" : "once");
        return start(description.trim(), name, Math.max(afterTicks, 0), everyTicks, 0, false,
                body, sender, captured);
    }

    /** Backward-compatible overload (unnamed schedule expression). */
    public static ScheduleHandle startExpression(long afterTicks, long everyTicks,
            ExecuteBlock body, CommandSender sender, Map<String, Object> captured) {
        return startExpression(afterTicks, everyTicks, null, body, sender, captured);
    }

    /**
     * Start a fixed-count {@code repeat N times [every dur]} schedule: fire
     * the body exactly {@code count} times then auto-stop. With no explicit
     * {@code every}, fires on consecutive ticks. {@code stop}/{@code run}
     * work inside; a non-positive count fires zero times.
     */
    public static ScheduleHandle startRepeat(int count, long everyTicks, String name,
            ExecuteBlock body, CommandSender sender, Map<String, Object> captured) {
        String description = "repeat " + count + "x"
                + (everyTicks > 0 ? " every " + everyTicks + "t" : "");
        return start(description, name, 0, everyTicks, Math.max(count, 0), true, body, sender,
                captured);
    }

    private static ScheduleHandle start(String description, String name, long initialDelayTicks,
            long everyTicks, int repeatCount, boolean bounded, ExecuteBlock body,
            CommandSender sender, Map<String, Object> captured) {
        ScheduleHandle handle = new ScheduleHandle(description);
        if (name != null) {
            ScheduleRegistry.register(name, handle);
        }
        // `bounded` marks a fixed-count repeat schedule regardless of the count
        // value, so `repeat 0 times` (bounded, count 0) is distinguishable from
        // an unbounded `every` (not bounded, count 0) — the latter must not be
        // treated as a zero-count repeat.
        // repeat with no explicit interval fires on consecutive ticks
        long spacing = bounded && everyTicks <= 0 ? 1 : everyTicks;
        AsyncRuntime.start("schedule " + description, () -> {
            try {
                if (initialDelayTicks > 0) {
                    TickClock.after(initialDelayTicks).get();
                }
                if (bounded && repeatCount <= 0) {
                    return; // repeat <= 0 times: fire nothing
                }
                while (!handle.isCancelled()) {
                    int run = handle.nextRun();
                    runBody(body, sender, captured, description, handle, run);
                    if (handle.isCancelled()) {
                        break; // stop was called during this fire
                    }
                    if (bounded && run >= repeatCount) {
                        break; // fixed-count exhausted -> auto-stop
                    }
                    if (spacing <= 0) {
                        break; // one-shot (schedule after ...)
                    }
                    TickClock.after(spacing).get();
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } catch (Exception e) {
                System.err.println("[schedule " + description + "] " + e.getMessage());
            } finally {
                handle.cancel();
                handle.markFinished();
                ScheduleRegistry.release(handle);
            }
        });
        return handle;
    }

    private static void runBody(ExecuteBlock body, CommandSender sender,
            Map<String, Object> captured, String description, ScheduleHandle handle, int run) {
        try {
            Map<String, Object> variables = captured != null
                    ? captured : new java.util.HashMap<>();
            // v2 bindings: 1-based run counter + the enclosing handle (so a
            // nested `stop` can reach it, even through an async{} snapshot)
            variables.put("run", run);
            variables.put(HANDLE_KEY, handle);
            new ASTExecutor(sender, variables).execute(body);
        } catch (Exception e) {
            System.err.println("[schedule " + description + "] body failed: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static CommandSender handlerSender() {
        try {
            return MinecraftServer.getCommandManager().getConsoleSender();
        } catch (Throwable t) {
            return SystemSender.INSTANCE;
        }
    }
}
