package net.swofty.nativebridge.execution.commands.combat;

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
import net.swofty.combat.CombatRuntime;
import net.swofty.entities.ScriptEntityRegistry;
import net.swofty.mobs.SwoftMob;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;

/**
 * shoot "&lt;projectile&gt;" from &lt;location&gt; [with velocity &lt;vec&gt;]
 * [by &lt;shooter&gt;] (was spawn_projectile). Spawns + fires the projectile on
 * the tick thread: like launch projectile it fires the cancellable
 * EntityShootEvent (handler power rescales the velocity) before placing +
 * velocitying it, so ProjectileCollide* events fire on impact. An absent
 * velocity spawns the projectile at rest (falls under gravity).
 */
public class ShootStatement extends AbstractAstNode implements Statement {
    private static final double TICKS_PER_SECOND = 20.0;

    private final Expression type;
    private final Expression from;
    private final Expression velocity;
    private final Expression shooter;

    public ShootStatement(Expression type, Expression from,
                          Expression velocity, Expression shooter) {
        this.type = type;
        this.from = from;
        this.velocity = velocity;
        this.shooter = shooter;
    }

    @Override
    public void execute(ExecutionContext context) {
        String typeName = (String) Coercions.toStringValue(context.evaluate(type));
        EntityType projectileType = SwoftMob.resolveType(typeName);
        Pos spawn = (Pos) Coercions.toPos(context.evaluate(from));
        Vec projVelocity = velocity != null
                ? (Vec) Coercions.toVec(context.evaluate(velocity))
                : Vec.ZERO;

        Object shooterVal = shooter != null ? context.evaluate(shooter) : null;
        Entity shooterEntity = (shooterVal == null || NoneValue.isNone(shooterVal))
                ? null
                : CombatRuntime.asEntity(shooterVal, "the projectile shooter");

        Instance instance = shooterEntity != null && shooterEntity.getInstance() != null
                ? shooterEntity.getInstance()
                : InstanceRegistry.get("world");
        if (instance == null) {
            throw new ScriptError("shoot: no world to spawn the projectile in");
        }

        EntityProjectile projectile = new EntityProjectile(shooterEntity, projectileType);
        TickDispatch.call(() -> {
            double length = projVelocity.length();
            Vec direction = length > 0 ? projVelocity.normalize() : Vec.ZERO;
            double power = length / TICKS_PER_SECOND;
            Vec launch = projVelocity;
            if (shooterEntity != null) {
                EntityShootEvent shootEvent = new EntityShootEvent(shooterEntity,
                        projectile, spawn.add(direction), power, 0.0);
                EventDispatcher.call(shootEvent);
                if (shootEvent.isCancelled()) {
                    projectile.remove();
                    return null;
                }
                if (shootEvent.getPower() != power && length > 0) {
                    launch = direction.mul(shootEvent.getPower() * TICKS_PER_SECOND);
                }
            }
            projectile.setInstance(instance, spawn);
            projectile.setVelocity(launch);
            ScriptEntityRegistry.track(projectile);
            return null;
        });
    }
}
