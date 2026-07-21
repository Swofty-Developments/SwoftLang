package net.swofty.event;

import java.util.List;
import java.util.Map;

import net.minestom.server.event.Event;
import net.swofty.event.EventPropertyResolver.Handle;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ServerValue;

/**
 * The OOP receiver dispatch table: for each {@code (eventName, receiverType)}
 * pair it records how to derive the method's {@code this} subject and its
 * positional arguments from the underlying Minestom (or custom net.swofty)
 * event.
 *
 * <p>This is the runtime half of the design's event&rarr;receiver.method
 * mapping. One native event that fans out to several receivers is emitted by
 * the compiler as several {@code events} entries sharing a name (one per
 * receiver), so each entry resolves to exactly one {@link Spec} here and the
 * fan-out is realized as multiple listeners on the same event node — the
 * existing {@link EventRegistrar} model.
 *
 * <p>Events without an explicit spec fall back to the generic player binding
 * in {@link ReceiverDispatch} (subject = the event's player, args bound by
 * catalog property name), so an unmapped receiver method never crashes.
 */
public final class ReceiverBinding {

    /** Read one value out of a live event (catalog handles supplied). */
    @FunctionalInterface
    public interface Reader {
        Object read(Event event, Map<String, Handle> handles);
    }

    /** Write one value back into a live event, or no-op when not settable. */
    @FunctionalInterface
    public interface Writer {
        void write(Event event, Map<String, Handle> handles, Object value);
    }

    /**
     * One positional argument: how to read it for binding and (optionally) how
     * to flush a mutated binder value back after a sync body runs.
     */
    public record Arg(Reader reader, Writer writer) {
        public boolean settable() {
            return writer != null;
        }
    }

    /**
     * One receiver method's binding recipe. {@code minestomClass} names the
     * Minestom/custom event class to listen on (null &rarr; derive from the
     * curated {@link EventType} map / {@link EventCatalog}); {@code subject}
     * yields {@code this}; {@code args} bind positionally to the method params.
     */
    public record Spec(String receiver, String method, String minestomClass,
                       Reader subject, List<Arg> args) {
    }

    private ReceiverBinding() {
    }

    // ------------------------------------------------------------------
    // reader/arg helpers
    // ------------------------------------------------------------------

    /** Read a catalog property by name (none when the class has no such row). */
    private static Object readProp(Event event, Map<String, Handle> handles, String name) {
        Handle handle = handles.get(name.toLowerCase(java.util.Locale.ROOT));
        if (handle == null) {
            return NoneValue.INSTANCE;
        }
        return EventPropertyResolver.read(event, handle);
    }

    /** A catalog-property subject/arg reader. */
    private static Reader prop(String name) {
        return (event, handles) -> readProp(event, handles, name);
    }

    /** A read-only positional arg backed by a catalog property. */
    private static Arg arg(String name) {
        return new Arg(prop(name), null);
    }

    /** A settable positional arg backed by a catalog property (flushed on exit). */
    private static Arg rwArg(String name) {
        String key = name.toLowerCase(java.util.Locale.ROOT);
        return new Arg(prop(name), (event, handles, value) -> {
            Handle handle = handles.get(key);
            if (handle != null && handle.settable()) {
                EventPropertyResolver.write(event, handle, value);
            }
        });
    }

    /** A positional arg from a direct, type-safe reader over the raw event. */
    private static Arg custom(Reader reader) {
        return new Arg(reader, null);
    }

    private static final Reader SERVER = (event, handles) -> ServerValue.INSTANCE;

    // ------------------------------------------------------------------
    // the table
    // ------------------------------------------------------------------

    private static final Map<String, Map<String, Spec>> TABLE = build();

    /** The spec for a receiver method, or null to use the generic fallback. */
    public static Spec lookup(String eventName, String receiver) {
        Map<String, Spec> byReceiver = TABLE.get(eventName);
        return byReceiver == null ? null : byReceiver.get(receiver);
    }

    private static Map<String, Map<String, Spec>> build() {
        java.util.Map<String, java.util.Map<String, Spec>> t = new java.util.HashMap<>();

        // --- Player receiver: mostly handled by the generic player fallback
        // (subject = player, args bound by catalog property name). Only the
        // handlers whose args are NOT plain catalog rows need an explicit spec.
        put(t, "PlayerChat", spec("Player", "on_chat", null, prop("player"), List.of(
                new Arg((e, h) -> ((net.minestom.server.event.player.PlayerChatEvent) e)
                        .getRawMessage(),
                        (e, h, v) -> ((net.minestom.server.event.player.PlayerChatEvent) e)
                                .setFormattedMessage(net.kyori.adventure.text.Component.text(
                                        String.valueOf(v)))))));

        // --- Entity / Mob receiver (subject = the involved entity).
        entity(t, "EntityDamage", "on_hit", List.of(arg("attacker")));
        entity(t, "EntityAttack", "on_attack", List.of(arg("target")));
        entity(t, "EntityDeath", "on_death", List.of());
        entity(t, "EntitySpawn", "on_spawn", List.of());
        entity(t, "EntityTick", "on_tick", List.of());
        entity(t, "EntityDespawn", "on_despawn", List.of());
        entity(t, "EntityTeleport", "on_teleport", List.of(arg("new_position")));
        entity(t, "EntityVelocity", "on_velocity", List.of(rwArg("velocity")));
        entity(t, "EntityShoot", "on_shoot",
                List.of(arg("projectile"), arg("to"), rwArg("power"), rwArg("spread")));
        entity(t, "EntitySetFire", "on_set_fire", List.of(rwArg("fire_ticks")));

        // Mob click rides the player-interact event; `this` is the target mob.
        mobOnly(t, "PlayerEntityInteract", "on_click", prop("target"), List.of(arg("player")));

        // Custom net.swofty mob events (typed views of the entity events).
        mobOnly(t, "MobSpawn", "on_spawn",
                (e, h) -> ((net.swofty.mobs.event.MobSpawnEvent) e).getMob(), List.of());
        mobOnly(t, "MobDeath", "on_death",
                (e, h) -> ((net.swofty.mobs.event.MobDeathEvent) e).getMob(),
                List.of(custom((e, h) -> nz(((net.swofty.mobs.event.MobDeathEvent) e).getKiller()))));
        mobOnly(t, "MobDamage", "on_hit",
                (e, h) -> ((net.swofty.mobs.event.MobDamageEvent) e).getMob(),
                List.of(custom((e, h) -> nz(((net.swofty.mobs.event.MobDamageEvent) e)
                        .getAttacker()))));
        put(t, "MobDamage", "net.swofty.mobs.event.MobDamageEvent");

        // --- Projectile receiver (subject = the projectile entity).
        one(t, "ProjectileCollideWithBlock", "Projectile", "on_hit_block", null,
                (e, h) -> ((net.minestom.server.event.entity.projectile.ProjectileCollideWithBlockEvent) e)
                        .getEntity(),
                List.of(arg("block"), arg("instance")));
        one(t, "ProjectileCollideWithEntity", "Projectile", "on_hit_entity", null,
                (e, h) -> ((net.minestom.server.event.entity.projectile.ProjectileCollideWithEntityEvent) e)
                        .getEntity(),
                List.of(arg("target")));

        // --- Item receiver (subject = the involved ItemStack).
        one(t, "ItemDrop", "Item", "on_drop", null, prop("item_stack"),
                List.of(arg("player")));
        one(t, "PickupItem", "Item", "on_pickup", null, prop("item_stack"),
                List.of(arg("living_entity")));

        // --- Block receiver (subject = the positioned block value / name).
        one(t, "BlockBreak", "Block", "on_break",
                "net.minestom.server.event.player.PlayerBlockBreakEvent",
                prop("block"), List.of(arg("player")));
        one(t, "BlockPlace", "Block", "on_place",
                "net.minestom.server.event.player.PlayerBlockPlaceEvent",
                prop("block"), List.of(arg("player"), arg("location"), arg("block")));
        one(t, "PlayerBlockInteract", "Block", "on_interact", null, prop("block"),
                List.of(arg("player"), arg("location"), arg("block")));
        one(t, "BlockDispense", "Block", "on_dispense",
                "net.swofty.blocks.event.BlockDispenseEvent",
                (e, h) -> ((net.swofty.blocks.event.BlockDispenseEvent) e).getBlock().name(),
                List.of(custom((e, h) -> ((net.swofty.blocks.event.BlockDispenseEvent) e).getItem()),
                        custom((e, h) -> ((net.swofty.blocks.event.BlockDispenseEvent) e)
                                .getDirection())));

        // --- Inventory receiver (subject = the open inventory).
        one(t, "InventoryPreClick", "Inventory", "on_pre_click", null, prop("inventory"),
                List.of(arg("player"), arg("slot"), arg("clicked_item")));
        one(t, "InventoryClick", "Inventory", "on_click", null, prop("inventory"),
                List.of(arg("player"), arg("slot"), arg("click_type"), arg("clicked_item")));
        one(t, "InventoryOpen", "Inventory", "on_open", null, prop("inventory"),
                List.of(arg("player")));
        one(t, "InventoryClose", "Inventory", "on_close", null, prop("inventory"),
                List.of(arg("player"), arg("from_client")));

        // --- World / Instance receiver (subject = the instance).
        world(t, "InstanceTick", "on_tick", List.of(arg("duration")));
        world(t, "InstanceRegister", "on_register", List.of());
        world(t, "InstanceUnregister", "on_unregister", List.of());
        world(t, "InstanceChunkLoad", "on_chunk_load", List.of(arg("chunk_x"), arg("chunk_z")));
        world(t, "InstanceChunkUnload", "on_chunk_unload", List.of(arg("chunk_x"), arg("chunk_z")));
        world(t, "AddEntityToInstance", "on_entity_add", List.of(arg("entity")));
        world(t, "RemoveEntityFromInstance", "on_entity_remove", List.of(arg("entity")));

        // --- Server receiver (subject = the server singleton; connection-only
        // events have no Player yet, so they can only live here).
        one(t, "ServerListPing", "Server", "on_list_ping",
                "net.minestom.server.event.server.ServerListPingEvent", SERVER,
                List.of(rwArg("status")));
        one(t, "ServerTickMonitor", "Server", "on_tick_monitor",
                "net.minestom.server.event.server.ServerTickMonitorEvent", SERVER, List.of());
        one(t, "ClientPingServer", "Server", "on_client_ping", null, SERVER,
                List.of(rwArg("delay"), rwArg("payload")));
        one(t, "AsyncPlayerPreLogin", "Server", "on_pre_login", null, SERVER,
                List.of(arg("connection"), rwArg("username"), rwArg("game_profile")));
        one(t, "AsyncPlayerConfiguration", "Server", "on_player_configuration", null, SERVER,
                List.of(arg("player"), rwArg("spawning_instance"), rwArg("hardcore")));
        one(t, "TpsChange", "Server", "on_tps_change", "net.swofty.tps.TpsChangeEvent", SERVER,
                List.of(custom((e, h) -> readProp(e, h, "past")),
                        custom((e, h) -> readProp(e, h, "current"))));

        // deep-copy into an immutable structure
        java.util.Map<String, java.util.Map<String, Spec>> out = new java.util.HashMap<>();
        for (var e : t.entrySet()) {
            out.put(e.getKey(), Map.copyOf(e.getValue()));
        }
        return Map.copyOf(out);
    }

    // ------------------------------------------------------------------
    // small builders
    // ------------------------------------------------------------------

    private static Object nz(Object value) {
        return value == null ? NoneValue.INSTANCE : value;
    }

    private static Spec spec(String receiver, String method, String cls, Reader subject,
            List<Arg> args) {
        return new Spec(receiver, method, cls, subject, args);
    }

    private static void put(java.util.Map<String, java.util.Map<String, Spec>> t, String event,
            Spec spec) {
        t.computeIfAbsent(event, k -> new java.util.HashMap<>()).put(spec.receiver(), spec);
    }

    /** Override just the minestomClass on the already-registered spec for event. */
    private static void put(java.util.Map<String, java.util.Map<String, Spec>> t, String event,
            String cls) {
        var byRecv = t.get(event);
        if (byRecv == null) {
            return;
        }
        for (var e : new java.util.HashMap<>(byRecv).entrySet()) {
            Spec s = e.getValue();
            byRecv.put(e.getKey(), new Spec(s.receiver(), s.method(), cls, s.subject(), s.args()));
        }
    }

    /** Register a spec under both Entity and Mob (shared entity subject). */
    private static void entity(java.util.Map<String, java.util.Map<String, Spec>> t, String event,
            String method, List<Arg> args) {
        put(t, event, spec("Entity", method, null, prop("entity"), args));
        put(t, event, spec("Mob", method, null, prop("entity"), args));
    }

    private static void mobOnly(java.util.Map<String, java.util.Map<String, Spec>> t, String event,
            String method, Reader subject, List<Arg> args) {
        put(t, event, spec("Mob", method, null, subject, args));
        put(t, event, spec("Entity", method, null, subject, args));
    }

    private static void world(java.util.Map<String, java.util.Map<String, Spec>> t, String event,
            String method, List<Arg> args) {
        put(t, event, spec("World", method, null, prop("instance"), args));
    }

    private static void one(java.util.Map<String, java.util.Map<String, Spec>> t, String event,
            String receiver, String method, String cls, Reader subject, List<Arg> args) {
        put(t, event, spec(receiver, method, cls, subject, args));
    }
}
