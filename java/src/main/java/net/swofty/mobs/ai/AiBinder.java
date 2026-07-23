package net.swofty.mobs.ai;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Predicate;

import net.minestom.server.entity.Entity;
import net.minestom.server.entity.EntityType;
import net.minestom.server.entity.LivingEntity;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.ai.GoalSelector;
import net.minestom.server.entity.ai.TargetSelector;
import net.minestom.server.entity.ai.target.ClosestEntityTarget;
import net.minestom.server.entity.ai.target.LastEntityDamagerTarget;
import net.swofty.ASTExecutor;
import net.swofty.mobs.SwoftMob;
import net.swofty.nativebridge.execution.Expression;

/**
 * Turns a parsed {@link AiBlock} into a live Minestom {@code EntityAIGroup} on a
 * {@link SwoftMob} (design v1.9.0 §2-4): natural/block target selectors +
 * priority-ordered scripted goal selectors, wired through {@code addAIGroup}.
 * One {@code ai { }} block = one AI group, coexisting with (here: replacing) the
 * preset {@code ai:} bundles.
 */
public final class AiBinder {

    private AiBinder() {
    }

    public static void apply(SwoftMob mob, AiBlock block) {
        List<TargetSelector> targets = buildTargets(mob, block.targets());
        List<GoalSelector> goals = buildGoals(mob, block);
        mob.addAIGroup(goals, targets);
    }

    // ---- targets (§4) --------------------------------------------------

    private static List<TargetSelector> buildTargets(SwoftMob mob, List<AiTarget> decls) {
        List<TargetSelector> out = new ArrayList<>();
        for (AiTarget decl : decls) {
            if (decl.isNatural()) {
                out.add(naturalSelector(mob, decl));
            } else {
                out.add(new ScriptedTargetSelector(mob, decl.body()));
            }
        }
        return out;
    }

    private static TargetSelector naturalSelector(SwoftMob mob, AiTarget decl) {
        double range = evalRange(mob, decl.range());
        return switch (decl.select()) {
            case "player" -> new ClosestEntityTarget(mob, range,
                    entity -> entity instanceof Player player && !player.isDead());
            case "hostile" -> new ClosestEntityTarget(mob, range, AiBinder::isHostile);
            case "last_attacker" -> new LastEntityDamagerTarget(mob, (float) range);
            case "mob_type" -> {
                String typeName = decl.mobType();
                Predicate<Entity> matches = mobTypePredicate(typeName);
                yield new ClosestEntityTarget(mob, range,
                        entity -> entity != mob && matches.test(entity));
            }
            default -> new ClosestEntityTarget(mob, range,
                    entity -> entity instanceof Player player && !player.isDead());
        };
    }

    /**
     * A best-effort "hostile" heuristic Minestom lacks a first-class marker for:
     * any non-player living entity that is not the mob itself.
     */
    private static boolean isHostile(Entity entity) {
        return entity instanceof LivingEntity living
                && !(entity instanceof Player)
                && !living.isDead();
    }

    /**
     * {@code closest <MobType> within n}: match either a custom mob type (by its
     * declared type name, e.g. {@code Guardian}) or a vanilla entity type key
     * (e.g. {@code Zombie} =&gt; {@code minecraft:zombie}).
     */
    private static Predicate<Entity> mobTypePredicate(String typeName) {
        EntityType vanilla = tryResolveType(typeName);
        return entity -> {
            if (entity instanceof SwoftMob sm
                    && sm.getDef().typeName().equalsIgnoreCase(typeName)) {
                return true;
            }
            return vanilla != null && entity.getEntityType() == vanilla;
        };
    }

    private static EntityType tryResolveType(String typeName) {
        try {
            return SwoftMob.resolveType(typeName);
        } catch (RuntimeException e) {
            return null; // a custom mob type name, not a vanilla entity type
        }
    }

    private static double evalRange(SwoftMob mob, Expression range) {
        if (range == null) {
            return 16.0;
        }
        try {
            Object value = new ASTExecutor(null, mobVars(mob)).evaluateExpression(range);
            return value instanceof Number number ? number.doubleValue() : 16.0;
        } catch (Exception e) {
            return 16.0;
        }
    }

    private static java.util.Map<String, Object> mobVars(SwoftMob mob) {
        java.util.Map<String, Object> vars = new java.util.HashMap<>();
        vars.put("mob", mob);
        return vars;
    }

    // ---- goals (§3, priority ordering) ---------------------------------

    /** An intermediate goal entry carrying its effective sort priority. */
    private record Entry(String name, GoalLifecycle life, int priority, int order) {
    }

    private static List<GoalSelector> buildGoals(SwoftMob mob, AiBlock block) {
        List<Entry> entries = new ArrayList<>();
        int order = 0;
        for (AiGoal goal : block.goals()) {
            int priority = goal.priority() != null ? goal.priority() : order;
            entries.add(new Entry(goal.name(), goal.lifecycle(), priority, order));
            order++;
        }
        for (GoalRef ref : block.goalRefs()) {
            GoalLifecycle life = GoalTypeRegistry.get(ref.name());
            if (life == null) {
                System.err.println("Warning: mob '" + mob.getDef().id()
                        + "' references unknown goal type '" + ref.name() + "'");
                order++;
                continue;
            }
            int priority = ref.priority() != null ? ref.priority() : order;
            entries.add(new Entry(ref.name(), life, priority, order));
            order++;
        }
        // Declaration order = priority (first = highest); explicit `priority N`
        // overrides (lower N = higher). Stable sort keeps declaration order on ties.
        entries.sort((a, b) -> {
            int cmp = Integer.compare(a.priority(), b.priority());
            return cmp != 0 ? cmp : Integer.compare(a.order(), b.order());
        });
        List<GoalSelector> out = new ArrayList<>();
        for (Entry entry : entries) {
            out.add(new ScriptedGoalSelector(mob, entry.name(), entry.life()));
        }
        return out;
    }
}
