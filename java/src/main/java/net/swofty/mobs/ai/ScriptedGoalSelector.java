package net.swofty.mobs.ai;

import java.util.HashMap;
import java.util.Map;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.ai.GoalSelector;
import net.swofty.ASTExecutor;
import net.swofty.handlers.HandlerDispatch;
import net.swofty.mobs.SwoftMob;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.props.NoneValue;
import net.swofty.runtime.SystemSender;
import net.swofty.runtime.Values;

/**
 * A {@link GoalSelector} whose five lifecycle hooks delegate to the emitted
 * script bodies of one scripted goal (design v1.9.0 §3). Every hook runs on the
 * tick thread with the BARE-CONTEXT binding shared by the whole AI surface:
 * {@code mob} = this {@link SwoftMob} (typed as its custom mob type for
 * property/receiver resolution) and {@code target} = the group's current
 * {@link TargetSelector} result as an {@code Optional<Entity>} (an {@link Entity}
 * or {@link NoneValue}, narrowed in-script with {@code exists} / {@code is
 * none}).
 *
 * <p>Priority ordering is realised by {@link AiBinder} placing the selectors in
 * the {@code EntityAIGroup} list in priority order; Minestom's group runs the
 * first goal whose {@code shouldStart} is true until its {@code shouldEnd}.
 * Bodies are error-isolated so a misbehaving goal never takes down the tick.
 */
public final class ScriptedGoalSelector extends GoalSelector {

    private final SwoftMob mob;
    private final String goalName;
    private final GoalLifecycle life;

    public ScriptedGoalSelector(SwoftMob mob, String goalName, GoalLifecycle life) {
        super(mob);
        this.mob = mob;
        this.goalName = goalName;
        this.life = life;
    }

    /** The scripted goal's declared name (for diagnostics / harness introspection). */
    public String goalName() {
        return goalName;
    }

    /** The bare-context vars for one hook invocation ({@code mob}, {@code target}). */
    private Map<String, Object> vars() {
        Map<String, Object> vars = new HashMap<>();
        vars.put("mob", mob);
        Entity target = findTarget();
        vars.put("target", target != null ? target : NoneValue.INSTANCE);
        return vars;
    }

    private boolean evalCond(Expression cond, boolean fallback) {
        if (cond == null) {
            return fallback;
        }
        try {
            Object value = new ASTExecutor(sender(), vars()).evaluateExpression(cond);
            return Values.toBoolean(value);
        } catch (Exception e) {
            System.err.println("Error in goal '" + goalName + "' condition: " + e.getMessage());
            return fallback;
        }
    }

    private void runBody(ExecuteBlock body) {
        HandlerDispatch.run(sender(), body, vars(), "goal '" + goalName + "'");
    }

    @Override
    public boolean shouldStart() {
        // GoalSelector default is start-true; a missing should_start keeps that.
        return evalCond(life.shouldStart(), true);
    }

    @Override
    public void start() {
        runBody(life.onStart());
    }

    @Override
    public void tick(long time) {
        runBody(life.onTick());
    }

    @Override
    public boolean shouldEnd() {
        // Default false => the goal runs until a higher-priority goal interrupts.
        return evalCond(life.shouldEnd(), false);
    }

    @Override
    public void end() {
        runBody(life.onEnd());
    }

    private static CommandSender sender() {
        try {
            return MinecraftServer.getCommandManager().getConsoleSender();
        } catch (Throwable t) {
            return SystemSender.INSTANCE;
        }
    }
}
