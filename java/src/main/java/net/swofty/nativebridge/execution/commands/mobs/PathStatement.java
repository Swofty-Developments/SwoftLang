package net.swofty.nativebridge.execution.commands.mobs;

import net.minestom.server.coordinate.Point;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.EntityCreature;
import net.minestom.server.entity.attribute.Attribute;
import net.swofty.ScriptError;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * {@code path <mob> to <Entity|Location> [at speed <n>]} (design v1.9.0 §5):
 * starts or continues an A* path to the goal via the creature's
 * {@code Navigator.setPathTo}. An {@code at speed} modifier sets the creature's
 * movement-speed attribute for the path (the navigator follows at that speed).
 *
 * <p>The destination may be a goal's bound {@code target}, which is an
 * {@code Optional<Entity>} — the compiler permits it without a presence check.
 * A {@code none} destination (no current target) is therefore a silent no-op,
 * consistent with {@code look at target}, so an unguarded {@code path mob to
 * target} does nothing rather than erroring each tick.
 */
public class PathStatement extends AbstractAstNode implements Statement {
    private final Expression mob;
    private final Expression to;
    private final Expression speed;

    public PathStatement(Expression mob, Expression to, Expression speed) {
        this.mob = mob;
        this.to = to;
        this.speed = speed;
    }

    @Override
    public void execute(ExecutionContext context) {
        EntityCreature creature = requireCreature(context.evaluate(mob));
        Object destination = context.evaluate(to);
        if (net.swofty.props.NoneValue.isNone(destination)) {
            // `path mob to target` with no current target: no destination to
            // path toward this tick, so do nothing (mirrors `look at`).
            return;
        }
        Point point = toPoint(destination);
        if (speed != null) {
            Object value = context.evaluate(speed);
            if (value instanceof Number number) {
                creature.getAttribute(Attribute.MOVEMENT_SPEED).setBaseValue(number.doubleValue());
            }
        }
        creature.getNavigator().setPathTo(point);
    }

    static EntityCreature requireCreature(Object value) {
        if (value instanceof EntityCreature creature) {
            return creature;
        }
        throw new ScriptError("path expects a mob, got: " + Values.displayString(value));
    }

    static Point toPoint(Object value) {
        if (value instanceof Pos pos) {
            return pos;
        }
        if (value instanceof Point point) {
            return point;
        }
        if (value instanceof Entity entity) {
            return entity.getPosition();
        }
        throw new ScriptError("path target must be an entity or a location, got: "
                + Values.displayString(value));
    }
}
