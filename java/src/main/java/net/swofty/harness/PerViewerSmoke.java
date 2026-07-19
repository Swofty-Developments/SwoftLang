package net.swofty.harness;

import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.Metadata;
import net.minestom.server.entity.MetadataDef;
import net.minestom.server.network.packet.server.SendablePacket;
import net.minestom.server.network.packet.server.play.EntityMetaDataPacket;
import net.minestom.server.network.player.GameProfile;
import net.minestom.server.network.player.PlayerConnection;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.block.Block;
import net.swofty.InstanceRegistry;
import net.swofty.async.TickClock;
import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.entities.EntityNametagRuntime;
import net.swofty.entities.ViewerControl;
import net.swofty.mobs.MobRegistry;
import net.swofty.mobs.SwoftMob;
import net.swofty.model.MobDefModel;
import net.swofty.props.PropertyTables;

/**
 * --perviewer-smoke &lt;compiled.json&gt;: a fake-player proof of the three
 * W-viewers features against the exact {@code perviewer.sw} demo:
 *
 * <ul>
 *   <li>{@code viewable: false} =&gt; the mob spawns with auto-view OFF and zero
 *       viewers (hidden until an explicit {@code show});</li>
 *   <li>{@code show z to p1} adds exactly p1 as a viewer;</li>
 *   <li>the typed {@code map<Player, Integer>} tag {@code hits} seeds empty and
 *       increments PER PLAYER independently on the ONE entity (p1 and p2 keep
 *       separate counts);</li>
 *   <li>{@code set name of mob to ... for attacker} sends a per-viewer name
 *       metadata packet to ONLY that attacker's connection;</li>
 *   <li>{@code hide z from p1} removes p1 as a viewer and drops the override.</li>
 * </ul>
 */
public final class PerViewerSmoke {

    private PerViewerSmoke() {
    }

    private static void stage(String s) {
        System.out.println("[PERVIEW] .. " + s);
        System.out.flush();
    }

    @SuppressWarnings("unchecked")
    public static int run(String jsonPath) throws Exception {
        stage("init server");
        MinecraftServer.init();
        MinecraftServer.getExceptionManager().setExceptionHandler(Throwable::printStackTrace);
        PropertyTables.ensureRegistered();
        TickClock.init();
        EntityNametagRuntime.init();
        EntityNametagRuntime.teardown();

        InstanceContainer instance = MinecraftServer.getInstanceManager()
                .createInstanceContainer();
        instance.setGenerator(unit -> unit.modifier().fillHeight(0, 64, Block.STONE));
        instance.loadChunk(0, 0).join();
        InstanceRegistry.register("world", instance);

        int failures = 0;

        // two fake players IN the instance, so an auto-viewable entity WOULD see
        // them — proving viewable:false is what keeps them off the viewer set.
        stage("spawn players");
        FakeConnection p1Wire = new FakeConnection();
        FakeConnection p2Wire = new FakeConnection();
        Player p1 = new Player(p1Wire, new GameProfile(UUID.randomUUID(), "P1"));
        Player p2 = new Player(p2Wire, new GameProfile(UUID.randomUUID(), "P2"));
        p1.setInstance(instance, new Pos(0.5, 65, 0.5)).join();
        p2.setInstance(instance, new Pos(1.5, 65, 0.5)).join();

        // register the compiled mob def(s), exactly as SwoftLangEngine does
        stage("register mob def");
        ParsedScript parsed = SwoftJsonLoader.load(Files.readString(Path.of(jsonPath)));
        MobRegistry.clear();
        for (MobDefModel def : parsed.mobs()) {
            MobRegistry.register(def);
        }
        failures += expect("one mob declared", 1, parsed.mobs().size());
        failures += expect("mob decl parsed viewable:false", false,
                parsed.mobs().get(0).viewable());

        // ----- viewable:false => auto-view OFF, zero viewers at spawn
        stage("spawn viewable:false mob");
        SwoftMob z = MobRegistry.spawn("zombie", new Pos(0.5, 65, 3.5), instance);
        failures += expect("mob is not auto-viewable (viewable:false wired to "
                        + "setAutoViewable)", false, z.isAutoViewable());
        failures += expect("viewable:false => zero auto viewers at spawn", 0,
                z.getViewers().size());

        // the typed tag seeded as a real, empty, live map (no NBT)
        Object hitsRaw = z.liveTag("hits");
        failures += expect("typed tag 'hits' seeded as a live MapValue", true,
                hitsRaw instanceof net.swofty.runtime.MapValue);
        failures += expect("seeded 'hits' map starts empty", 0,
                hitsRaw instanceof Map ? ((Map<Object, Object>) hitsRaw).size() : -1);

        // ----- show z to p1 => exactly one viewer, p1
        stage("show z to p1");
        ViewerControl.show(z, p1);
        failures += expect("show z to p1 => one viewer", 1, z.getViewers().size());
        failures += expect("the viewer is p1", true, z.getViewers().contains(p1));
        failures += expect("p2 is NOT a viewer", false, z.getViewers().contains(p2));

        // ----- per-player typed-tag isolation: hit p1 twice, p2 once, on the
        // SAME entity. The on_hit body does map_set hits[attacker] to
        // (hits[attacker] otherwise 0)+1, so counts must not bleed across players.
        stage("per-player hits[] isolation");
        z.handleMeleeHit(p1);
        z.handleMeleeHit(p1);
        z.handleMeleeHit(p2);
        Map<Object, Object> hits = (Map<Object, Object>) z.liveTag("hits");
        // map<Player,..> keys normalize to the player's uuid string (Values.coerceMapKey)
        Object k1 = p1.getUuid().toString();
        Object k2 = p2.getUuid().toString();
        failures += expect("p1's independent hit count is 2", 2, asInt(hits.get(k1)));
        failures += expect("p2's independent hit count is 1", 1, asInt(hits.get(k2)));
        failures += expect("two distinct player keys on one live map", 2, hits.size());

        // ----- per-viewer name went to ONLY the hit attacker's connection.
        // Each on_hit ran `set name of mob to ... for attacker`.
        stage("per-viewer nametag targeting");
        failures += expect("p1 received per-viewer name metadata packet(s)", true,
                p1Wire.sawEntityMeta(z.getEntityId()));
        failures += expect("p2 received a per-viewer name packet (from its own hit)",
                true, p2Wire.sawEntityMeta(z.getEntityId()));
        failures += expect("both p1 and p2 hold a name override on the entity", 2,
                EntityNametagRuntime.overrideCount(z));

        // isolate: set a name for ONLY p1 on a fresh entity, p2 must see nothing
        stage("per-viewer nametag isolation");
        SwoftMob z2 = MobRegistry.spawn("zombie", new Pos(0.5, 65, 6.5), instance);
        ViewerControl.show(z2, p1);
        ViewerControl.show(z2, p2);
        p1Wire.sent.clear();
        p2Wire.sent.clear();
        EntityNametagRuntime.set(z2, "<gold>Only P1 sees this", p1);
        failures += expect("p1 got the per-viewer name for z2", true,
                p1Wire.sawEntityMeta(z2.getEntityId()));
        failures += expect("p2 did NOT get p1's per-viewer name for z2", false,
                p2Wire.sawEntityMeta(z2.getEntityId()));
        failures += expect("exactly one viewer holds an override on z2", 1,
                EntityNametagRuntime.overrideCount(z2));
        // the metadata payload is the custom-name rows and nothing else
        EntityMetaDataPacket namePkt = p1Wire.lastEntityMeta(z2.getEntityId());
        failures += expect("name packet carries the CUSTOM_NAME metadata row", true,
                namePkt != null && namePkt.entries()
                        .containsKey(MetadataDef.CUSTOM_NAME.index()));
        failures += expect("name packet carries CUSTOM_NAME_VISIBLE=true", true,
                namePkt != null && Boolean.TRUE.equals(valueOf(namePkt.entries()
                        .get(MetadataDef.CUSTOM_NAME_VISIBLE.index()))));

        // ----- hide z from p1 => removed, and the override is dropped
        stage("hide z from p1");
        ViewerControl.hide(z, p1);
        failures += expect("hide z from p1 => p1 no longer a viewer", false,
                z.getViewers().contains(p1));
        failures += expect("hiding dropped p1's name override on z", true,
                !holdsOverride(z, p1));

        // ----- disconnect cleanup: no leaked overrides for a gone player
        stage("disconnect cleanup");
        EntityNametagRuntime.set(z, "<red>tmp", p2);
        int before = EntityNametagRuntime.overrideCount(z);
        net.minestom.server.event.EventDispatcher.call(
                new net.minestom.server.event.player.PlayerDisconnectEvent(p2));
        failures += expect("p2 held an override before disconnect", true, before >= 1);
        failures += expect("disconnect purged p2's override (no leak)", true,
                !holdsOverride(z, p2));

        System.out.println("[PERVIEW] " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures == 0 ? 0 : 1;
    }

    private static boolean holdsOverride(SwoftMob mob, Player viewer) {
        // re-derive from the public counter by toggling would be invasive; instead
        // reset() is a no-op if absent — use the override count delta via a probe.
        // Simpler: a viewer holds an override iff clearing changes the count.
        int before = EntityNametagRuntime.overrideCount(mob);
        EntityNametagRuntime.clearHidden(mob, viewer);
        int after = EntityNametagRuntime.overrideCount(mob);
        return before != after;
    }

    private static int asInt(Object o) {
        return o instanceof Number n ? n.intValue() : Integer.MIN_VALUE;
    }

    private static Object valueOf(Metadata.Entry<?> entry) {
        return entry == null ? null : entry.value();
    }

    private static int expect(String what, Object expected, Object actual) {
        if (expected.equals(actual)) {
            return 0;
        }
        System.err.println("[PERVIEW] FAIL " + what + ": expected " + expected
                + ", got " + actual);
        return 1;
    }

    /** Records outbound packets so per-viewer EntityMetaData can be asserted. */
    static final class FakeConnection extends PlayerConnection {
        final java.util.List<SendablePacket> sent = new CopyOnWriteArrayList<>();

        @Override
        public void sendPacket(SendablePacket packet) {
            sent.add(packet);
        }

        @Override
        public SocketAddress getRemoteAddress() {
            return new InetSocketAddress(0);
        }

        boolean sawEntityMeta(int entityId) {
            return lastEntityMeta(entityId) != null;
        }

        EntityMetaDataPacket lastEntityMeta(int entityId) {
            EntityMetaDataPacket found = null;
            for (SendablePacket packet : sent) {
                if (packet instanceof EntityMetaDataPacket meta
                        && meta.entityId() == entityId) {
                    found = meta;
                }
            }
            return found;
        }
    }
}
