package net.swofty.props;

import java.util.ArrayList;
import java.util.List;

import net.kyori.adventure.text.Component;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.GameMode;
import net.minestom.server.entity.LivingEntity;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.attribute.Attribute;
import net.minestom.server.component.DataComponents;
import net.minestom.server.item.ItemStack;
import net.minestom.server.item.Material;
import net.swofty.TextFormat;
import net.swofty.event.events.SwoftPlayerChatEvent;
import net.swofty.event.events.SwoftPlayerJoinEvent;

import static net.swofty.props.ThreadPolicy.ANY;
import static net.swofty.props.ThreadPolicy.TICK;

/**
 * The complete script-visible property whitelist for Minestom types and the
 * SwoftLang event wrappers. Signatures verified against
 * net.minestom:minestom-snapshots:ebaa2bbf64 (ItemComponent constants, not
 * DataComponents; EquipmentHandler lives in net.minestom.server.inventory).
 */
public final class PropertyTables {
    private static boolean registered = false;

    private PropertyTables() {
    }

    public static synchronized void ensureRegistered() {
        if (registered) {
            return;
        }
        registered = true;
        registerEntity();
        registerPlayer();
        registerCombatSurface();
        registerPos();
        registerVec();
        registerItemStack();
        registerBlockValue();
        registerTasks();
        registerEventWrappers();

        // Phase-5 content rows (items/mobs namespaces + event wrappers)
        net.swofty.items.ItemProperties.ensureRegistered();
        net.swofty.mobs.MobProperties.ensureRegistered();
        registerContentEventWrappers();

        // Phase-6 rows (displays/http/music/tps/worlds/skins/sched)
        net.swofty.displays.DisplayProperties.ensureRegistered();
        net.swofty.http.HttpRuntime.registerProperties();
        net.swofty.music.MusicRuntime.registerProperties();
        registerInstanceRows();
        registerServerValue();
        registerSkinRows();
        registerCanvasRows();
        registerScheduleRows();
        registerPhase6EventWrappers();

        // Phase-8 rows (offline players + fishing events)
        net.swofty.players.OfflinePlayerProperties.ensureRegistered();
        registerPhase8EventWrappers();

        // Phase-10 rows (command preprocess event)
        registerPhase10EventWrappers();
    }

    /** PlayerCommand wrapper rows (phase 10): player ro, command rw, veto. */
    private static void registerPhase10EventWrappers() {
        PropertyRegistry.register(PropertyDef.readOnly("player",
                net.swofty.event.events.SwoftPlayerCommandEvent.class,
                net.swofty.event.events.SwoftPlayerCommandEvent::getPlayer));
        PropertyRegistry.register(PropertyDef.of("command",
                net.swofty.event.events.SwoftPlayerCommandEvent.class,
                net.swofty.event.events.SwoftPlayerCommandEvent::getCommand,
                (event, value) -> event.setCommand((String) value),
                null, Coercions::toStringValue, ANY));
        PropertyRegistry.register(PropertyDef.of("cancelled",
                net.swofty.event.events.SwoftPlayerCommandEvent.class,
                net.swofty.event.events.SwoftPlayerCommandEvent::isCancelled,
                (event, value) -> event.setCancelled((Boolean) value),
                null, Coercions::toBoolean, ANY));
    }

    /** CastRod / FishBite / CatchFish / ReelIn wrappers (phase 8). */
    private static void registerPhase8EventWrappers() {
        PropertyRegistry.register(PropertyDef.readOnly("player",
                net.swofty.event.events.SwoftPlayerCastRodEvent.class,
                net.swofty.event.events.SwoftPlayerCastRodEvent::getPlayer));
        PropertyRegistry.register(PropertyDef.of("cancelled",
                net.swofty.event.events.SwoftPlayerCastRodEvent.class,
                net.swofty.event.events.SwoftPlayerCastRodEvent::isCancelled,
                (event, value) -> event.setCancelled((Boolean) value),
                null, Coercions::toBoolean, ANY));

        PropertyRegistry.register(PropertyDef.readOnly("player",
                net.swofty.event.events.SwoftFishBiteEvent.class,
                net.swofty.event.events.SwoftFishBiteEvent::getPlayer));
        PropertyRegistry.register(PropertyDef.readOnly("hook_location",
                net.swofty.event.events.SwoftFishBiteEvent.class,
                net.swofty.event.events.SwoftFishBiteEvent::getHookLocation));

        PropertyRegistry.register(PropertyDef.readOnly("player",
                net.swofty.event.events.SwoftPlayerCatchFishEvent.class,
                net.swofty.event.events.SwoftPlayerCatchFishEvent::getPlayer));
        PropertyRegistry.register(PropertyDef.of("caught_item",
                net.swofty.event.events.SwoftPlayerCatchFishEvent.class,
                net.swofty.event.events.SwoftPlayerCatchFishEvent::getCaughtItem,
                (event, value) -> event.setCaughtItem((ItemStack) value),
                null, Coercions::toItemStack, ANY));
        PropertyRegistry.register(PropertyDef.readOnly("caught_mob",
                net.swofty.event.events.SwoftPlayerCatchFishEvent.class,
                net.swofty.event.events.SwoftPlayerCatchFishEvent::getCaughtMob));
        PropertyRegistry.register(PropertyDef.readOnly("hook_location",
                net.swofty.event.events.SwoftPlayerCatchFishEvent.class,
                net.swofty.event.events.SwoftPlayerCatchFishEvent::getHookLocation));
        PropertyRegistry.register(PropertyDef.of("cancelled",
                net.swofty.event.events.SwoftPlayerCatchFishEvent.class,
                net.swofty.event.events.SwoftPlayerCatchFishEvent::isCancelled,
                (event, value) -> event.setCancelled((Boolean) value),
                null, Coercions::toBoolean, ANY));

        PropertyRegistry.register(PropertyDef.readOnly("player",
                net.swofty.event.events.SwoftPlayerReelInEvent.class,
                net.swofty.event.events.SwoftPlayerReelInEvent::getPlayer));
    }

    /** World time rows (design 6D): &lt;world&gt;.time settable, time_rate. */
    private static void registerInstanceRows() {
        PropertyRegistry.register(PropertyDef.of("time",
                net.minestom.server.instance.Instance.class,
                net.minestom.server.instance.Instance::getTime,
                (instance, value) -> instance.setTime(((Number) value).longValue()),
                null, Coercions::toDouble, TICK));
        PropertyRegistry.register(PropertyDef.of("time_rate",
                net.minestom.server.instance.Instance.class,
                // getTimeRate/setTimeRate were folded into the per-instance Clock
                // (rate() is a float now); time_rate stays an integer script row.
                instance -> (int) instance.defaultClock().rate(),
                (instance, value) -> instance.defaultClock().rate(((Integer) value).floatValue()),
                null, Coercions::toInt, TICK));
        // phase-10: weather. Instance.setWeather broadcasts the state to
        // viewers, so admin.md's weather commands re-port as plain writes.
        PropertyRegistry.register(PropertyDef.of("weather",
                net.minestom.server.instance.Instance.class,
                instance -> weatherName(instance.getWeather()),
                (instance, value) -> instance.setWeather(
                        (net.minestom.server.instance.Weather) value),
                null, PropertyTables::coerceWeather, TICK));
        PropertyRegistry.register(PropertyDef.readOnly("raining",
                net.minestom.server.instance.Instance.class,
                instance -> instance.getWeather().rainLevel() > 0f));
        PropertyRegistry.register(PropertyDef.readOnly("thundering",
                net.minestom.server.instance.Instance.class,
                instance -> instance.getWeather().thunderLevel() > 0f));
    }

    /** Weather record -> clear|rain|thunder script name. */
    private static String weatherName(net.minestom.server.instance.Weather weather) {
        if (weather.thunderLevel() > 0f) {
            return "thunder";
        }
        return weather.rainLevel() > 0f ? "rain" : "clear";
    }

    /** clear|rain|thunder -> Weather; ScriptError on anything else. */
    private static Object coerceWeather(Object value) {
        String name = String.valueOf(Coercions.toStringValue(value))
                .toLowerCase(java.util.Locale.ROOT);
        switch (name) {
            case "clear":
                return net.minestom.server.instance.Weather.CLEAR;
            case "rain":
            case "raining":
                return net.minestom.server.instance.Weather.RAIN;
            case "thunder":
            case "thundering":
            case "storm":
                return net.minestom.server.instance.Weather.THUNDER;
            default:
                throw new net.swofty.ScriptError("unknown weather '"
                        + Coercions.toStringValue(value)
                        + "' (valid: clear, rain, thunder)");
        }
    }

    /** server.tps / average_tps / mspt / motd (design 6B/6D). */
    private static void registerServerValue() {
        PropertyRegistry.register(PropertyDef.readOnly("tps",
                net.swofty.runtime.ServerValue.class,
                server -> net.swofty.tps.TpsMonitor.instance().tps()));
        PropertyRegistry.register(PropertyDef.readOnly("average_tps",
                net.swofty.runtime.ServerValue.class,
                server -> net.swofty.tps.TpsMonitor.instance().averageTps()));
        PropertyRegistry.register(PropertyDef.readOnly("mspt",
                net.swofty.runtime.ServerValue.class,
                server -> net.swofty.tps.TpsMonitor.instance().mspt()));
        PropertyRegistry.register(PropertyDef.of("motd",
                net.swofty.runtime.ServerValue.class,
                server -> net.swofty.motd.MotdRuntime.getMotd(),
                (server, value) -> net.swofty.motd.MotdRuntime.setMotd((String) value),
                null, Coercions::toStringValue, ANY));
    }

    /** &lt;player&gt;.skin (settable) + Skin value rows (design 6D). */
    private static void registerSkinRows() {
        PropertyRegistry.register(PropertyDef.of("skin", Player.class,
                player -> {
                    net.minestom.server.entity.PlayerSkin skin = player.getSkin();
                    return skin != null ? skin : net.swofty.props.NoneValue.INSTANCE;
                },
                (player, value) -> player.setSkin(
                        (net.minestom.server.entity.PlayerSkin) value),
                null, value -> {
                    if (value instanceof net.minestom.server.entity.PlayerSkin skin) {
                        return skin;
                    }
                    throw new net.swofty.ScriptError("expected a skin (use skin(texture, "
                            + "signature) or fetch_skin(username)), got: " + value);
                }, TICK));
        PropertyRegistry.register(PropertyDef.readOnly("texture",
                net.minestom.server.entity.PlayerSkin.class,
                net.minestom.server.entity.PlayerSkin::textures));
        PropertyRegistry.register(PropertyDef.readOnly("signature",
                net.minestom.server.entity.PlayerSkin.class,
                skin -> skin.signature() != null ? skin.signature()
                        : net.swofty.props.NoneValue.INSTANCE));
    }

    /** Canvas rows (design 6D). */
    private static void registerCanvasRows() {
        PropertyRegistry.register(PropertyDef.readOnly("width",
                net.swofty.maps.MapCanvas.class, canvas -> net.swofty.maps.MapCanvas.SIZE));
        PropertyRegistry.register(PropertyDef.readOnly("height",
                net.swofty.maps.MapCanvas.class, canvas -> net.swofty.maps.MapCanvas.SIZE));
        PropertyRegistry.register(PropertyDef.readOnly("map_id",
                net.swofty.maps.MapCanvas.class, net.swofty.maps.MapCanvas::mapId));
    }

    /** Schedule handle rows (design 6D). */
    private static void registerScheduleRows() {
        PropertyRegistry.register(PropertyDef.readOnly("active",
                net.swofty.sched.ScheduleHandle.class,
                net.swofty.sched.ScheduleHandle::isActive));
        PropertyRegistry.register(PropertyDef.readOnly("cancelled",
                net.swofty.sched.ScheduleHandle.class,
                net.swofty.sched.ScheduleHandle::isCancelled));
    }

    /** TpsChange / BlockBreak / BlockPlace / ServerPing wrappers (phase 6). */
    private static void registerPhase6EventWrappers() {
        PropertyRegistry.register(PropertyDef.readOnly("past",
                net.swofty.event.events.SwoftTpsChangeEvent.class,
                net.swofty.event.events.SwoftTpsChangeEvent::getPast));
        PropertyRegistry.register(PropertyDef.readOnly("current",
                net.swofty.event.events.SwoftTpsChangeEvent.class,
                net.swofty.event.events.SwoftTpsChangeEvent::getCurrent));
        PropertyRegistry.register(PropertyDef.readOnly("tps",
                net.swofty.event.events.SwoftTpsChangeEvent.class,
                net.swofty.event.events.SwoftTpsChangeEvent::getTps));

        PropertyRegistry.register(PropertyDef.readOnly("player",
                net.swofty.event.events.SwoftBlockBreakEvent.class,
                net.swofty.event.events.SwoftBlockBreakEvent::getPlayer));
        PropertyRegistry.register(PropertyDef.readOnly("block",
                net.swofty.event.events.SwoftBlockBreakEvent.class,
                net.swofty.event.events.SwoftBlockBreakEvent::getBlock));
        PropertyRegistry.register(PropertyDef.readOnly("location",
                net.swofty.event.events.SwoftBlockBreakEvent.class,
                net.swofty.event.events.SwoftBlockBreakEvent::getLocation));
        PropertyRegistry.register(PropertyDef.of("cancelled",
                net.swofty.event.events.SwoftBlockBreakEvent.class,
                net.swofty.event.events.SwoftBlockBreakEvent::isCancelled,
                (event, value) -> event.setCancelled((Boolean) value),
                null, Coercions::toBoolean, ANY));
        PropertyRegistry.register(PropertyDef.readOnly("block_face",
                net.swofty.event.events.SwoftBlockBreakEvent.class,
                net.swofty.event.events.SwoftBlockBreakEvent::getBlockFace));
        PropertyRegistry.register(PropertyDef.of("result_block",
                net.swofty.event.events.SwoftBlockBreakEvent.class,
                net.swofty.event.events.SwoftBlockBreakEvent::getResultBlock,
                (event, value) -> event.setResultBlock((String) value),
                null, Coercions::toStringValue, ANY));

        PropertyRegistry.register(PropertyDef.readOnly("player",
                net.swofty.event.events.SwoftBlockPlaceEvent.class,
                net.swofty.event.events.SwoftBlockPlaceEvent::getPlayer));
        PropertyRegistry.register(PropertyDef.readOnly("block",
                net.swofty.event.events.SwoftBlockPlaceEvent.class,
                net.swofty.event.events.SwoftBlockPlaceEvent::getBlock));
        PropertyRegistry.register(PropertyDef.readOnly("location",
                net.swofty.event.events.SwoftBlockPlaceEvent.class,
                net.swofty.event.events.SwoftBlockPlaceEvent::getLocation));
        PropertyRegistry.register(PropertyDef.of("cancelled",
                net.swofty.event.events.SwoftBlockPlaceEvent.class,
                net.swofty.event.events.SwoftBlockPlaceEvent::isCancelled,
                (event, value) -> event.setCancelled((Boolean) value),
                null, Coercions::toBoolean, ANY));
        PropertyRegistry.register(PropertyDef.readOnly("block_face",
                net.swofty.event.events.SwoftBlockPlaceEvent.class,
                net.swofty.event.events.SwoftBlockPlaceEvent::getBlockFace));
        PropertyRegistry.register(PropertyDef.readOnly("hand",
                net.swofty.event.events.SwoftBlockPlaceEvent.class,
                net.swofty.event.events.SwoftBlockPlaceEvent::getHand));
        PropertyRegistry.register(PropertyDef.readOnly("cursor_position",
                net.swofty.event.events.SwoftBlockPlaceEvent.class,
                net.swofty.event.events.SwoftBlockPlaceEvent::getCursorPosition));

        PropertyRegistry.register(PropertyDef.of("motd",
                net.swofty.event.events.SwoftServerPingEvent.class,
                net.swofty.event.events.SwoftServerPingEvent::getMotd,
                (event, value) -> event.setMotd((String) value),
                null, Coercions::toStringValue, ANY));
        PropertyRegistry.register(PropertyDef.of("online",
                net.swofty.event.events.SwoftServerPingEvent.class,
                net.swofty.event.events.SwoftServerPingEvent::getOnline,
                (event, value) -> event.setOnline((Integer) value),
                null, Coercions::toInt, ANY));
        PropertyRegistry.register(PropertyDef.of("max",
                net.swofty.event.events.SwoftServerPingEvent.class,
                net.swofty.event.events.SwoftServerPingEvent::getMax,
                (event, value) -> event.setMax((Integer) value),
                null, Coercions::toInt, ANY));
    }

    private static void registerContentEventWrappers() {
        PropertyRegistry.register(PropertyDef.readOnly("mob",
                net.swofty.event.events.SwoftMobSpawnEvent.class,
                net.swofty.event.events.SwoftMobSpawnEvent::getMob));

        PropertyRegistry.register(PropertyDef.readOnly("mob",
                net.swofty.event.events.SwoftMobDeathEvent.class,
                net.swofty.event.events.SwoftMobDeathEvent::getMob));
        PropertyRegistry.register(PropertyDef.readOnly("killer",
                net.swofty.event.events.SwoftMobDeathEvent.class,
                net.swofty.event.events.SwoftMobDeathEvent::getKiller));

        PropertyRegistry.register(PropertyDef.readOnly("mob",
                net.swofty.event.events.SwoftMobDamageEvent.class,
                net.swofty.event.events.SwoftMobDamageEvent::getMob));
        PropertyRegistry.register(PropertyDef.readOnly("attacker",
                net.swofty.event.events.SwoftMobDamageEvent.class,
                net.swofty.event.events.SwoftMobDamageEvent::getAttacker));
        PropertyRegistry.register(PropertyDef.of("damage",
                net.swofty.event.events.SwoftMobDamageEvent.class,
                net.swofty.event.events.SwoftMobDamageEvent::getDamage,
                (event, value) -> event.setDamage(((Number) value).doubleValue()),
                null, Coercions::toDouble, ANY));
        PropertyRegistry.register(PropertyDef.of("cancelled",
                net.swofty.event.events.SwoftMobDamageEvent.class,
                net.swofty.event.events.SwoftMobDamageEvent::isCancelled,
                (event, value) -> event.setCancelled((Boolean) value),
                null, Coercions::toBoolean, ANY));

        PropertyRegistry.register(PropertyDef.readOnly("player",
                net.swofty.event.events.SwoftPlayerUseItemEvent.class,
                net.swofty.event.events.SwoftPlayerUseItemEvent::getPlayer));
        PropertyRegistry.register(PropertyDef.readOnly("item",
                net.swofty.event.events.SwoftPlayerUseItemEvent.class,
                net.swofty.event.events.SwoftPlayerUseItemEvent::getItem));
        PropertyRegistry.register(PropertyDef.readOnly("custom_id",
                net.swofty.event.events.SwoftPlayerUseItemEvent.class,
                net.swofty.event.events.SwoftPlayerUseItemEvent::getCustomId));
        PropertyRegistry.register(PropertyDef.readOnly("activation",
                net.swofty.event.events.SwoftPlayerUseItemEvent.class,
                net.swofty.event.events.SwoftPlayerUseItemEvent::getActivation));
        PropertyRegistry.register(PropertyDef.of("cancelled",
                net.swofty.event.events.SwoftPlayerUseItemEvent.class,
                net.swofty.event.events.SwoftPlayerUseItemEvent::isCancelled,
                (event, value) -> event.setCancelled((Boolean) value),
                null, Coercions::toBoolean, ANY));

        // Phase-9 dispenser runtime: BlockDispense wrapper rows
        PropertyRegistry.register(PropertyDef.readOnly("location",
                net.swofty.event.events.SwoftBlockDispenseEvent.class,
                net.swofty.event.events.SwoftBlockDispenseEvent::getLocation));
        PropertyRegistry.register(PropertyDef.readOnly("block",
                net.swofty.event.events.SwoftBlockDispenseEvent.class,
                net.swofty.event.events.SwoftBlockDispenseEvent::getBlock));
        PropertyRegistry.register(PropertyDef.of("item",
                net.swofty.event.events.SwoftBlockDispenseEvent.class,
                net.swofty.event.events.SwoftBlockDispenseEvent::getItem,
                (event, value) -> event.setItem((ItemStack) value),
                null, Coercions::toItemStack, ANY));
        PropertyRegistry.register(PropertyDef.readOnly("direction",
                net.swofty.event.events.SwoftBlockDispenseEvent.class,
                net.swofty.event.events.SwoftBlockDispenseEvent::getDirection));
        PropertyRegistry.register(PropertyDef.of("cancelled",
                net.swofty.event.events.SwoftBlockDispenseEvent.class,
                net.swofty.event.events.SwoftBlockDispenseEvent::isCancelled,
                (event, value) -> event.setCancelled((Boolean) value),
                null, Coercions::toBoolean, ANY));
    }

    /**
     * The TEntity row set (phase 7): every Minestom entity — plain
     * spawned entities, mobs (SwoftMob IS an EntityCreature), players,
     * projectiles — resolves these through the superclass walk. More
     * specific rows (SwoftMob, Player) keep precedence.
     */
    private static void registerEntity() {
        // stringified to match the checker's TString row and uuid_of()
        PropertyRegistry.register(PropertyDef.readOnly("uuid", Entity.class,
                entity -> entity.getUuid().toString()));
        PropertyRegistry.register(PropertyDef.of("location", Entity.class,
                Entity::getPosition,
                (entity, pos) -> entity.teleport((Pos) pos),
                null, Coercions::toPos, TICK));
        PropertyRegistry.register(PropertyDef.readOnly("type", Entity.class,
                entity -> entity.getEntityType().key().asString()));
        PropertyRegistry.register(PropertyDef.of("velocity", Entity.class,
                Entity::getVelocity,
                (entity, value) -> entity.setVelocity(
                        (net.minestom.server.coordinate.Vec) value),
                null, Coercions::toVec, TICK));
        PropertyRegistry.register(PropertyDef.of("custom_name", Entity.class,
                entity -> {
                    Component name = entity.getCustomName();
                    return name != null ? TextFormat.plain(name) : "";
                },
                (entity, value) -> entity.setCustomName((Component) value),
                null, Coercions::toComponent, ANY));
        PropertyRegistry.register(PropertyDef.of("name_visible", Entity.class,
                Entity::isCustomNameVisible,
                (entity, value) -> entity.setCustomNameVisible((Boolean) value),
                null, Coercions::toBoolean, ANY));
        PropertyRegistry.register(PropertyDef.of("glowing", Entity.class,
                Entity::isGlowing,
                (entity, value) -> entity.setGlowing((Boolean) value),
                null, Coercions::toBoolean, ANY));
        PropertyRegistry.register(PropertyDef.of("invisible", Entity.class,
                Entity::isInvisible,
                (entity, value) -> entity.setInvisible((Boolean) value),
                null, Coercions::toBoolean, ANY));
        PropertyRegistry.register(PropertyDef.of("gravity", Entity.class,
                entity -> !entity.hasNoGravity(),
                (entity, value) -> entity.setNoGravity(!((Boolean) value)),
                null, Coercions::toBoolean, ANY));
        PropertyRegistry.register(PropertyDef.of("on_fire", Entity.class,
                Entity::isOnFire,
                // the pinned Entity has no setOnFire; the visual flag
                // lives on the entity meta
                (entity, value) -> entity.getEntityMeta().setOnFire((Boolean) value),
                null, Coercions::toBoolean, ANY));
        PropertyRegistry.register(PropertyDef.of("silent", Entity.class,
                Entity::isSilent,
                (entity, value) -> entity.setSilent((Boolean) value),
                null, Coercions::toBoolean, ANY));
        PropertyRegistry.register(PropertyDef.readOnly("passengers", Entity.class,
                entity -> new ArrayList<>(entity.getPassengers())));
        PropertyRegistry.register(PropertyDef.readOnly("vehicle", Entity.class,
                entity -> {
                    Entity vehicle = entity.getVehicle();
                    return vehicle != null ? vehicle : net.swofty.props.NoneValue.INSTANCE;
                }));
        PropertyRegistry.register(PropertyDef.readOnly("alive", Entity.class,
                entity -> !entity.isRemoved()));
        PropertyRegistry.register(PropertyDef.readOnly("removed", Entity.class,
                Entity::isRemoved));
        // W-pvp status getters: combat scripts read these off any entity
        // (players resolve them through the Entity superclass walk). velocity
        // sits above; food/food_saturation on the Player rows below.
        PropertyRegistry.register(PropertyDef.readOnly("on_ground", Entity.class,
                Entity::isOnGround));
        PropertyRegistry.register(PropertyDef.readOnly("is_sprinting", Entity.class,
                Entity::isSprinting));
        PropertyRegistry.register(PropertyDef.readOnly("alive_ticks", Entity.class,
                entity -> (int) entity.getAliveTicks()));
        // projectile ownership: the launching entity, none for everything else
        PropertyRegistry.register(PropertyDef.readOnly("shooter", Entity.class,
                entity -> entity instanceof net.minestom.server.entity.EntityProjectile
                        projectile && projectile.getShooter() != null
                        ? projectile.getShooter()
                        : net.swofty.props.NoneValue.INSTANCE));
        // phase-10: entity pose (snake_case of EntityPose) + sneaking sugar.
        // Mobs are Entities (SwoftMob IS an EntityCreature), so they inherit
        // both rows - wardensk re-ports its sniff toggle via pose.
        PropertyRegistry.register(PropertyDef.of("pose", Entity.class,
                entity -> poseName(entity.getPose()),
                (entity, value) -> entity.setPose(
                        (net.minestom.server.entity.EntityPose) value),
                null, PropertyTables::coercePose, ANY));
        PropertyRegistry.register(PropertyDef.of("sneaking", Entity.class,
                Entity::isSneaking,
                (entity, value) -> entity.setSneaking((Boolean) value),
                null, Coercions::toBoolean, ANY));
        // freeform nested entity tags: entity.tags.<path...> get/set/delete,
        // a pass-through hop returning an EntityTagsView that flushes back
        // onto the entity's TagHandler in place (mirrors item.tags). Mobs,
        // players and projectiles all inherit this via the superclass walk.
        PropertyRegistry.register(PropertyDef.passThroughHop("tags", Entity.class,
                net.swofty.entities.EntityTagsView::of,
                (entity, value) -> ((net.swofty.entities.EntityTagsView) value).applyToEntity(),
                value -> {
                    throw new net.swofty.ScriptError(
                            "entity.tags is not directly assignable - set entity.tags.<key> instead");
                }));
        // viewers of <entity> / entity.viewers: the entity's current viewers as
        // an ordered list<Player> (W-viewers feature 1). getViewers() is an
        // unordered set, so ViewerControl sorts by username for a stable order.
        PropertyRegistry.register(PropertyDef.readOnly("viewers", Entity.class,
                net.swofty.entities.ViewerControl::orderedViewers));
    }

    /**
     * W-pvp surface: the entity ATTRIBUTE keys as direct rw Double properties
     * (read e.armor = current value, set e.max_health = base value) plus the
     * native combat trackers as ro properties. Each attribute row is backed by
     * the SAME Attribute API the removed attribute/set_attribute builtins used;
     * "gravity" and "max_health" are skipped (handled by CombatRuntime's list)
     * so the pre-existing boolean gravity / rw max_health rows keep priority.
     */
    private static void registerCombatSurface() {
        for (String attrName : net.swofty.combat.CombatRuntime.ATTRIBUTE_PROPERTY_NAMES) {
            Attribute attr = net.swofty.combat.CombatRuntime.attributeFromName(attrName);
            PropertyRegistry.register(PropertyDef.of(attrName, LivingEntity.class,
                    entity -> entity.getAttributeValue(attr),
                    (entity, value) ->
                            entity.getAttribute(attr).setBaseValue(((Number) value).doubleValue()),
                    null, Coercions::toDouble, TICK));
        }
        // native trackers (Minestom exposes no first-class accessors): remaining
        // i-frame ticks, blocks fallen, positional climbing heuristic, and the
        // live potion-key list. All read-only, off the same runtime helpers the
        // removed invulnerable_ticks/fall_distance/is_climbing/active_effects
        // builtins called.
        PropertyRegistry.register(PropertyDef.readOnly("invulnerable_ticks", Entity.class,
                net.swofty.entities.EntityCombatTrackers::invulnerableTicks));
        PropertyRegistry.register(PropertyDef.readOnly("fall_distance", Entity.class,
                net.swofty.entities.EntityCombatTrackers::fallDistance));
        PropertyRegistry.register(PropertyDef.readOnly("is_climbing", Entity.class,
                net.swofty.entities.EntityCombatTrackers::isClimbing));
        PropertyRegistry.register(PropertyDef.readOnly("active_effects", Entity.class,
                net.swofty.combat.CombatRuntime::activeEffects));
    }

    /** EntityPose enum name -> lowercase snake_case script name. */
    private static String poseName(net.minestom.server.entity.EntityPose pose) {
        return pose.name().toLowerCase(java.util.Locale.ROOT);
    }

    /** snake_case script name -> EntityPose; ScriptError on an unknown pose. */
    private static Object coercePose(Object value) {
        String name = String.valueOf(Coercions.toStringValue(value))
                .toUpperCase(java.util.Locale.ROOT);
        try {
            return net.minestom.server.entity.EntityPose.valueOf(name);
        } catch (IllegalArgumentException e) {
            StringBuilder valid = new StringBuilder();
            for (net.minestom.server.entity.EntityPose pose
                    : net.minestom.server.entity.EntityPose.values()) {
                if (valid.length() > 0) {
                    valid.append(", ");
                }
                valid.append(poseName(pose));
            }
            throw new net.swofty.ScriptError("unknown pose '"
                    + Coercions.toStringValue(value) + "' (valid: " + valid + ")");
        }
    }

    /** Velocity vector rows (phase 7): read + wither, like Pos. */
    private static void registerVec() {
        Class<net.minestom.server.coordinate.Vec> vec =
                net.minestom.server.coordinate.Vec.class;
        PropertyRegistry.register(PropertyDef.of("x", vec,
                net.minestom.server.coordinate.Vec::x, null,
                (v, value) -> v.withX((double) (Double) value),
                Coercions::toDouble, ANY));
        PropertyRegistry.register(PropertyDef.of("y", vec,
                net.minestom.server.coordinate.Vec::y, null,
                (v, value) -> v.withY((double) (Double) value),
                Coercions::toDouble, ANY));
        PropertyRegistry.register(PropertyDef.of("z", vec,
                net.minestom.server.coordinate.Vec::z, null,
                (v, value) -> v.withZ((double) (Double) value),
                Coercions::toDouble, ANY));
        PropertyRegistry.register(PropertyDef.readOnly("length", vec,
                net.minestom.server.coordinate.Vec::length));
        // W-stdlib B7: the unit vector in the same direction (zero vector -> itself)
        PropertyRegistry.register(PropertyDef.readOnly("normalized", vec,
                v -> v.isZero() ? v : v.normalize()));
    }

    private static void registerPlayer() {
        PropertyRegistry.register(PropertyDef.readOnly("name", Player.class, Player::getUsername));
        PropertyRegistry.register(PropertyDef.of("health", LivingEntity.class,
                LivingEntity::getHealth,
                (entity, value) -> {
                    float max = (float) entity.getAttributeValue(Attribute.MAX_HEALTH);
                    entity.setHealth(Math.clamp(((Number) value).floatValue(), 0f, max));
                },
                null, Coercions::toFloat, TICK));
        PropertyRegistry.register(PropertyDef.of("max_health", LivingEntity.class,
                entity -> entity.getAttributeValue(Attribute.MAX_HEALTH),
                (entity, value) -> {
                    double max = ((Number) value).doubleValue();
                    entity.getAttribute(Attribute.MAX_HEALTH).setBaseValue(max);
                    if (entity.getHealth() > max) {
                        entity.setHealth((float) max);
                    }
                },
                null, Coercions.doubleAbove(0, "max_health"), TICK));
        PropertyRegistry.register(PropertyDef.of("food", Player.class,
                Player::getFood,
                (player, value) -> player.setFood((Integer) value),
                null, Coercions.intClamped(0, 20, "food"), TICK));
        PropertyRegistry.register(PropertyDef.of("food_saturation", Player.class,
                Player::getFoodSaturation,
                (player, value) -> player.setFoodSaturation((Float) value),
                null, Coercions.floatClamped(0f, 20f, "food_saturation"), TICK));
        PropertyRegistry.register(PropertyDef.of("level", Player.class,
                Player::getLevel,
                (player, value) -> player.setLevel((Integer) value),
                null, Coercions.intAtLeast(0, "level"), ANY));
        PropertyRegistry.register(PropertyDef.of("exp", Player.class,
                Player::getExp,
                (player, value) -> player.setExp((Float) value),
                null, Coercions.floatClamped(0f, 1f, "exp"), ANY));
        PropertyRegistry.register(PropertyDef.of("gamemode", Player.class,
                player -> player.getGameMode().name().toLowerCase(),
                (player, value) -> {
                    if (!player.setGameMode((GameMode) value)) {
                        System.err.println("Warning: gamemode change refused for "
                                + player.getUsername());
                    }
                },
                null, Coercions::toGameMode, TICK));
        PropertyRegistry.register(PropertyDef.of("world", Player.class,
                Player::getInstance,
                (player, value) -> player.setInstance((net.minestom.server.instance.Instance) value),
                null, Coercions::toInstance, TICK));
        PropertyRegistry.register(PropertyDef.of("held_item", Player.class,
                Player::getItemInMainHand,
                (player, value) -> player.setItemInMainHand((ItemStack) value),
                null, Coercions::toItemStack, TICK));
        PropertyRegistry.register(PropertyDef.of("held_slot", Player.class,
                Player::getHeldSlot,
                (player, value) -> player.setHeldItemSlot((Byte) value),
                null, Coercions::toHeldSlot, TICK));
        PropertyRegistry.register(PropertyDef.readOnly("latency", Player.class, Player::getLatency));
        PropertyRegistry.register(PropertyDef.of("display_name", Player.class,
                player -> {
                    Component displayName = player.getDisplayName();
                    return displayName != null ? TextFormat.plain(displayName) : player.getUsername();
                },
                (player, value) -> player.setDisplayName((Component) value),
                null, Coercions::toComponent, ANY));
        PropertyRegistry.register(PropertyDef.of("flying", Player.class,
                Player::isFlying,
                (player, value) -> {
                    if ((Boolean) value && !player.isAllowFlying()) {
                        System.err.println("Warning: setting flying while allow_flying is false");
                    }
                    player.setFlying((Boolean) value);
                },
                null, Coercions::toBoolean, TICK));
        PropertyRegistry.register(PropertyDef.of("allow_flying", Player.class,
                Player::isAllowFlying,
                (player, value) -> player.setAllowFlying((Boolean) value),
                null, Coercions::toBoolean, TICK));
        PropertyRegistry.register(PropertyDef.of("flying_speed", Player.class,
                Player::getFlyingSpeed,
                (player, value) -> player.setFlyingSpeed((Float) value),
                null, Coercions.floatAbove(0f, "flying_speed"), ANY));
        PropertyRegistry.register(PropertyDef.readOnly("online", Player.class, Player::isOnline));
    }

    private static void registerPos() {
        PropertyRegistry.register(PropertyDef.of("x", Pos.class,
                Pos::x, null, (pos, value) -> pos.withX((Double) value),
                Coercions::toDouble, ANY));
        PropertyRegistry.register(PropertyDef.of("y", Pos.class,
                Pos::y, null, (pos, value) -> pos.withY((Double) value),
                Coercions::toDouble, ANY));
        PropertyRegistry.register(PropertyDef.of("z", Pos.class,
                Pos::z, null, (pos, value) -> pos.withZ((Double) value),
                Coercions::toDouble, ANY));
        PropertyRegistry.register(PropertyDef.of("yaw", Pos.class,
                Pos::yaw, null, (pos, value) -> pos.withYaw((Float) value),
                Coercions::toFloat, ANY));
        PropertyRegistry.register(PropertyDef.of("pitch", Pos.class,
                Pos::pitch, null, (pos, value) -> pos.withPitch((Float) value),
                Coercions.floatClamped(-90f, 90f, "pitch"), ANY));
        PropertyRegistry.register(PropertyDef.readOnly("block_x", Pos.class, Pos::blockX));
        PropertyRegistry.register(PropertyDef.readOnly("block_y", Pos.class, Pos::blockY));
        PropertyRegistry.register(PropertyDef.readOnly("block_z", Pos.class, Pos::blockZ));
    }

    private static void registerItemStack() {
        PropertyRegistry.register(PropertyDef.of("material", ItemStack.class,
                stack -> stack.material().key().asString(),
                null, (stack, value) -> stack.withMaterial((Material) value),
                Coercions::toMaterial, ANY));
        PropertyRegistry.register(PropertyDef.of("amount", ItemStack.class,
                ItemStack::amount,
                null, (stack, value) -> stack.withAmount((Integer) value),
                Coercions::toItemAmount, ANY));
        PropertyRegistry.register(PropertyDef.of("name", ItemStack.class,
                stack -> {
                    Component customName = stack.get(DataComponents.CUSTOM_NAME);
                    return customName != null ? TextFormat.plain(customName) : "";
                },
                null, (stack, value) -> stack.with(DataComponents.CUSTOM_NAME, (Component) value),
                Coercions::toComponent, ANY));
        PropertyRegistry.register(PropertyDef.of("lore", ItemStack.class,
                stack -> {
                    List<Component> lore = stack.get(DataComponents.LORE);
                    if (lore == null) {
                        return new ArrayList<String>();
                    }
                    List<String> lines = new ArrayList<>(lore.size());
                    for (Component line : lore) {
                        lines.add(TextFormat.plain(line));
                    }
                    return lines;
                },
                null, (stack, value) -> {
                    @SuppressWarnings("unchecked")
                    List<Component> lore = (List<Component>) value;
                    return stack.with(DataComponents.LORE, lore);
                },
                Coercions::toComponentList, ANY));
    }

    /**
     * W-blocks: read-only accessors on a {@link net.swofty.blocks.BlockValue}
     * ({@code block.id}, {@code block.properties}, {@code block.nbt}). The
     * with/property/tag builders come in through method-call dispatch instead.
     */
    private static void registerBlockValue() {
        PropertyRegistry.register(PropertyDef.readOnly("id",
                net.swofty.blocks.BlockValue.class,
                net.swofty.blocks.BlockValue::id));
        PropertyRegistry.register(PropertyDef.readOnly("properties",
                net.swofty.blocks.BlockValue.class,
                net.swofty.blocks.BlockValue::properties));
        PropertyRegistry.register(PropertyDef.readOnly("nbt",
                net.swofty.blocks.BlockValue.class,
                net.swofty.blocks.BlockValue::nbt));
    }

    /**
     * W-tasks: the read side of the {@code <obj>.tasks.<id>} namespace. The
     * {@code tasks} hop returns a {@link net.swofty.tasks.TasksView} keyed by
     * owner identity, so {@code <obj>.tasks.<id>} resolves to the live
     * {@code Schedule} handle or {@code none}. Reads only — associating a task
     * uses the dedicated {@code set <obj>.tasks.<id> to schedule ...} statement,
     * never a generic property write. Registered on every task owner: Entity
     * (covers Player/Mob/Npc-entity via the superclass walk), display entities
     * (holograms), positioned block values, and offline players.
     */
    private static void registerTasks() {
        PropertyRegistry.register(PropertyDef.readOnly("tasks", Entity.class,
                net.swofty.tasks.TasksView::new));
        PropertyRegistry.register(PropertyDef.readOnly("tasks",
                net.swofty.displays.SwoftDisplay.class,
                net.swofty.tasks.TasksView::new));
        PropertyRegistry.register(PropertyDef.readOnly("tasks",
                net.swofty.blocks.BlockValue.class,
                net.swofty.tasks.TasksView::new));
        PropertyRegistry.register(PropertyDef.readOnly("tasks",
                net.swofty.players.OfflinePlayerValue.class,
                net.swofty.tasks.TasksView::new));
    }

    private static void registerEventWrappers() {
        PropertyRegistry.register(PropertyDef.readOnly("player", SwoftPlayerChatEvent.class,
                SwoftPlayerChatEvent::getPlayer));
        PropertyRegistry.register(PropertyDef.of("message", SwoftPlayerChatEvent.class,
                SwoftPlayerChatEvent::getMessage,
                (event, value) -> event.setMessage((String) value),
                null, Coercions::toStringValue, ANY));
        PropertyRegistry.register(PropertyDef.readOnly("raw_message", SwoftPlayerChatEvent.class,
                SwoftPlayerChatEvent::getRawMessage));
        PropertyRegistry.register(PropertyDef.readOnly("recipients", SwoftPlayerChatEvent.class,
                SwoftPlayerChatEvent::getRecipients));
        PropertyRegistry.register(PropertyDef.of("cancelled", SwoftPlayerChatEvent.class,
                SwoftPlayerChatEvent::isCancelled,
                (event, value) -> event.setCancelled((Boolean) value),
                null, Coercions::toBoolean, ANY));

        PropertyRegistry.register(PropertyDef.readOnly("player", SwoftPlayerJoinEvent.class,
                SwoftPlayerJoinEvent::getPlayer));
        PropertyRegistry.register(PropertyDef.readOnly("first_spawn", SwoftPlayerJoinEvent.class,
                event -> event.getMinestomEvent().isFirstSpawn()));
        PropertyRegistry.register(PropertyDef.readOnly("world", SwoftPlayerJoinEvent.class,
                event -> event.getMinestomEvent().getSpawnInstance()));
    }
}
