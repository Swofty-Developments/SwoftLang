package net.swofty.packets;

import java.lang.reflect.RecordComponent;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

import net.kyori.adventure.text.Component;
import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Point;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.event.player.PlayerPacketEvent;
import net.swofty.ASTExecutor;
import net.swofty.ScriptError;
import net.swofty.TextFormat;
import net.swofty.model.PacketHandlerModel;
import net.swofty.props.NoneValue;

/**
 * Inbound packet interception (design 5D): ONE global PlayerPacketEvent
 * listener dispatching on the packet class through a precomputed map -
 * never PacketListenerManager.setPlayListener, which irreversibly replaces
 * the vanilla listener. Packet fields are exposed read-only via cached
 * record components; "cancel packet" sets the event cancelled so the
 * vanilla handler is skipped.
 *
 * THREADING: play-state packets are drained at the start of Player#update,
 * so these handlers run on the player's instance tick thread - the same
 * context as every other SwoftLang event handler. EXCEPTION: the members
 * of PlayerSocketConnection.IMMEDIATE_PROCESS_PACKETS that can arrive in
 * the PLAY state (keepalive, ping request, cookie response) DO fire
 * PlayerPacketEvent, but on the network read thread - hence the blacklist
 * below (design D.3): scripts must never run there, and cancelling a
 * keepalive would skip latency bookkeeping and get the player kicked.
 */
public final class PacketListeners {
    /** Bound as a hidden variable so `cancel packet` can reach the event. */
    public static final String EVENT_VARIABLE = "__packet_event";

    /**
     * Play-capable IMMEDIATE_PROCESS_PACKETS (pinned ebaa2bbf64): processed
     * on the network read thread, so 'on packet' may not listen to them.
     */
    private static final java.util.Set<String> NETWORK_THREAD_PACKETS = java.util.Set.of(
            "ClientKeepAlivePacket", "ClientPingRequestPacket", "ClientCookieResponsePacket");

    private static final Map<Class<?>, List<PacketHandlerModel>> HANDLERS =
            new ConcurrentHashMap<>();
    private static boolean listenerInstalled = false;

    private PacketListeners() {
    }

    public static void clear() {
        HANDLERS.clear();
    }

    /**
     * Register one on packet handler; unknown or network-thread-processed
     * names are load errors.
     */
    public static void register(PacketHandlerModel model) {
        Class<?> packetClass;
        try {
            packetClass = PacketSender.resolveClient(model.name());
        } catch (ScriptError e) {
            System.err.println("Error: on packet \"" + model.name() + "\": " + e.getMessage());
            return;
        }
        if (NETWORK_THREAD_PACKETS.contains(packetClass.getSimpleName())) {
            System.err.println("Error: 'on packet' cannot listen to "
                    + packetClass.getSimpleName()
                    + ": it is processed immediately on the network read thread"
                    + " (script handlers only run on tick threads)");
            return;
        }
        HANDLERS.computeIfAbsent(packetClass, c -> new CopyOnWriteArrayList<>()).add(model);
        installListener();
    }

    private static synchronized void installListener() {
        if (listenerInstalled) {
            return;
        }
        listenerInstalled = true;
        MinecraftServer.getGlobalEventHandler().addListener(PlayerPacketEvent.class,
                PacketListeners::dispatch);
    }

    static void dispatch(PlayerPacketEvent event) {
        List<PacketHandlerModel> handlers = HANDLERS.get(event.getPacket().getClass());
        if (handlers == null || handlers.isEmpty()) {
            return;
        }
        Player player = event.getPlayer();
        Map<String, Object> packetView = readFields(event.getPacket());
        for (PacketHandlerModel handler : handlers) {
            Map<String, Object> variables = new java.util.HashMap<>();
            variables.put("player", player);
            variables.put("packet", packetView);
            variables.put(EVENT_VARIABLE, event);
            try {
                new ASTExecutor(player, variables).execute(handler.execute());
            } catch (Exception e) {
                System.err.println("Error in on packet \"" + handler.name() + "\" handler: "
                        + e.getMessage());
            }
        }
    }

    /**
     * Read-only packet.* view: record components converted to script values
     * (enums as strings, points as locations, components as MiniMessage).
     */
    public static Map<String, Object> readFields(Object packet) {
        Map<String, Object> view = new LinkedHashMap<>();
        if (!packet.getClass().isRecord()) {
            return view;
        }
        for (RecordComponent component : packet.getClass().getRecordComponents()) {
            try {
                view.put(component.getName(), toScriptValue(
                        component.getAccessor().invoke(packet)));
            } catch (Exception e) {
                view.put(component.getName(), NoneValue.INSTANCE);
            }
        }
        return view;
    }

    private static Object toScriptValue(Object value) {
        if (value == null) {
            return NoneValue.INSTANCE;
        }
        if (value instanceof Enum<?> constant) {
            return constant.name();
        }
        if (value instanceof Pos pos) {
            return pos;
        }
        if (value instanceof Point point) {
            return new Pos(point.x(), point.y(), point.z());
        }
        if (value instanceof Component component) {
            return TextFormat.plain(component);
        }
        return value;
    }

    /** Handler count for a resolved class (harness introspection). */
    public static int handlerCount(Class<?> packetClass) {
        List<PacketHandlerModel> handlers = HANDLERS.get(packetClass);
        return handlers == null ? 0 : handlers.size();
    }
}
