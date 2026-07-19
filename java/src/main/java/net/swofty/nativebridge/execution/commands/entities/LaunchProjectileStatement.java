package net.swofty.nativebridge.execution.commands.entities;

import net.minestom.server.coordinate.Pos;
import net.minestom.server.coordinate.Vec;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.EntityProjectile;
import net.minestom.server.entity.EntityType;
import net.minestom.server.event.EventDispatcher;
import net.minestom.server.event.entity.EntityShootEvent;
import net.minestom.server.instance.Instance;
import net.swofty.InstanceRegistry;
import net.swofty.ScriptError;
import net.swofty.async.TickDispatch;
import net.swofty.entities.ScriptEntityRegistry;
import net.swofty.mobs.SwoftMob;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;

/**
 * launch projectile "TYPE" from &lt;entity&gt; [with velocity &lt;v&gt; | with
 * speed N] [as &lt;var&gt;] (phase 7). Backed by the pinned EntityProjectile
 * (constructor (shooter, type)); the projectile spawns at the shooter's
 * eye position. Default velocity is the shooter's look direction times
 * the speed (default 1.5 blocks/tick), converted to the blocks-per-
 * second units Entity.setVelocity expects; an explicit velocity vector
 * is applied as-is. Launching fires the engine's EntityShootEvent like
 * EntityProjectile.shoot() (cancellable; handler power writes rescale
 * the velocity), and the projectile is tracked for the reload sweep.
 */
public class LaunchProjectileStatement extends AbstractAstNode implements Statement {
    /** Vanilla-arrow-ish default: 1.5 blocks per tick. */
    private static final double DEFAULT_SPEED = 1.5;
    private static final double TICKS_PER_SECOND = 20.0;

    private final Expression type;
    private final Expression shooter;
    private final Expression velocity;
    private final Expression speed;
    private final String bindVar;

    public LaunchProjectileStatement(Expression type, Expression shooter,
                                     Expression velocity, Expression speed, String bindVar) {
        this.type = type;
        this.shooter = shooter;
        this.velocity = velocity;
        this.speed = speed;
        this.bindVar = bindVar;
    }

    @Override
    public void execute(ExecutionContext context) {
        String typeName = (String) Coercions.toStringValue(context.evaluate(type));
        Object from = shooter != null ? context.evaluate(shooter) : context.getSender();
        Entity shooterEntity = EntityValues.asEntity(from, "launch projectile from");

        Instance instance = shooterEntity.getInstance() != null
                ? shooterEntity.getInstance()
                : InstanceRegistry.get("world");
        if (instance == null) {
            throw new ScriptError("launch projectile: the shooter is not in a world");
        }

        EntityType entityType = SwoftMob.resolveType(typeName);
        Vec launchVelocity = resolveVelocity(context, shooterEntity);
        Pos eye = shooterEntity.getPosition()
                .add(0, shooterEntity.getEyeHeight(), 0);

        EntityProjectile projectile = new EntityProjectile(shooterEntity, entityType);
        TickDispatch.call(() -> {
            // launching IS shooting: fire the engine's EntityShootEvent
            // exactly like EntityProjectile.shoot() does, honoring
            // cancellation and handler-adjusted power (blocks/tick)
            double length = launchVelocity.length();
            Vec direction = length > 0 ? launchVelocity.normalize() : Vec.ZERO;
            double power = length / TICKS_PER_SECOND;
            EntityShootEvent shootEvent = new EntityShootEvent(shooterEntity,
                    projectile, eye.add(direction), power, 0.0);
            EventDispatcher.call(shootEvent);
            if (shootEvent.isCancelled()) {
                projectile.remove();
                return null;
            }
            Vec velocity = launchVelocity;
            if (shootEvent.getPower() != power && length > 0) {
                velocity = direction.mul(shootEvent.getPower() * TICKS_PER_SECOND);
            }
            projectile.setInstance(instance, eye);
            projectile.setVelocity(velocity);
            ScriptEntityRegistry.track(projectile);
            return null;
        });
        if (bindVar != null) {
            context.getVariables().put(bindVar, projectile);
        }
    }

    private Vec resolveVelocity(ExecutionContext context, Entity shooterEntity) {
        if (velocity != null) {
            return (Vec) Coercions.toVec(context.evaluate(velocity));
        }
        double blocksPerTick = DEFAULT_SPEED;
        if (speed != null) {
            blocksPerTick = Coercions.requireNumber(context.evaluate(speed),
                    "projectile speed").doubleValue();
            if (blocksPerTick <= 0) {
                throw new ScriptError("projectile speed must be positive, got: "
                        + blocksPerTick);
            }
        }
        Vec direction = shooterEntity.getPosition().direction();
        return direction.normalize().mul(blocksPerTick * TICKS_PER_SECOND);
    }
}
