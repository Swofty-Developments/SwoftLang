package net.swofty.mobs;

import net.swofty.TextFormat;
import net.swofty.props.Coercions;
import net.swofty.props.PropertyDef;
import net.swofty.props.PropertyRegistry;
import net.swofty.props.ThreadPolicy;

/**
 * Mob value property rows (design 5B): custom_id/type/alive read-only,
 * name/damage/speed writable here; health, max_health and location come
 * from the inherited LivingEntity/Entity rows in PropertyTables.
 */
public final class MobProperties {
    private static boolean registered = false;

    private MobProperties() {
    }

    public static synchronized void ensureRegistered() {
        if (registered) {
            return;
        }
        registered = true;

        PropertyRegistry.register(PropertyDef.readOnly("custom_id", SwoftMob.class,
                SwoftMob::getCustomIdString));
        // contract: Mob.max_health is read-only (overrides the writable
        // LivingEntity row; most-specific registration wins)
        PropertyRegistry.register(PropertyDef.readOnly("max_health", SwoftMob.class,
                mob -> mob.getAttributeValue(
                        net.minestom.server.entity.attribute.Attribute.MAX_HEALTH)));
        PropertyRegistry.register(PropertyDef.readOnly("id", SwoftMob.class,
                SwoftMob::getCustomIdString));
        PropertyRegistry.register(PropertyDef.readOnly("type", SwoftMob.class,
                mob -> mob.getEntityType().key().asString()));
        PropertyRegistry.register(PropertyDef.readOnly("alive", SwoftMob.class,
                mob -> !mob.isDead() && !mob.isRemoved()));
        PropertyRegistry.register(PropertyDef.of("name", SwoftMob.class,
                mob -> {
                    var name = mob.getCustomName();
                    return name != null ? TextFormat.plain(name) : mob.getDef().id();
                },
                (mob, value) -> mob.setNameOverride((String) value),
                null, Coercions::toStringValue, ThreadPolicy.TICK));
        PropertyRegistry.register(PropertyDef.of("damage", SwoftMob.class,
                SwoftMob::getAttackDamage,
                (mob, value) -> mob.setAttackDamage(((Number) value).doubleValue()),
                null, Coercions::toDouble, ThreadPolicy.TICK));
        PropertyRegistry.register(PropertyDef.of("speed", SwoftMob.class,
                mob -> mob.getAttributeValue(
                        net.minestom.server.entity.attribute.Attribute.MOVEMENT_SPEED),
                (mob, value) -> mob.getAttribute(
                        net.minestom.server.entity.attribute.Attribute.MOVEMENT_SPEED)
                        .setBaseValue(((Number) value).doubleValue()),
                null, Coercions::toDouble, ThreadPolicy.TICK));
        // mob.tags: the typed-tag overlay (W-viewers feature 2). More specific
        // than the Entity 'tags' row, so it wins the class walk; declared typed
        // keys resolve to the live in-memory store, undeclared keys fall through
        // to freeform NBT (and flush back via MobTagsView.flush).
        PropertyRegistry.register(PropertyDef.passThroughHop("tags", SwoftMob.class,
                MobTagsView::of,
                (mob, value) -> ((MobTagsView) value).flush(),
                value -> {
                    throw new net.swofty.ScriptError(
                            "mob.tags is not directly assignable - set mob.tags.<key> instead");
                }));
    }
}
