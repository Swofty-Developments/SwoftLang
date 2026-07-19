package net.swofty.gui;

import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutionException;

import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Player;
import net.minestom.server.event.GlobalEventHandler;
import net.minestom.server.event.inventory.InventoryCloseEvent;
import net.minestom.server.event.inventory.InventoryPreClickEvent;
import net.minestom.server.event.player.PlayerDisconnectEvent;
import net.minestom.server.event.player.PlayerPacketEvent;
import net.minestom.server.network.packet.client.play.ClientUpdateSignPacket;
import net.minestom.server.thread.TickSchedulerThread;
import net.minestom.server.thread.TickThread;
import net.swofty.ASTExecutor;
import net.swofty.ScriptError;
import net.swofty.async.HaltSignal;
import net.swofty.async.TickDispatch;
import net.swofty.model.GuiModel;
import net.swofty.nativebridge.execution.Expression;

/**
 * Static facade for the GUI system: declaration registry, per-player
 * sessions, per-player navigation stacks, and the sign-editor prompt.
 * Mutating entry points hop to the tick thread through TickDispatch.
 */
public final class GuiRuntime {
    private record NavEntry(String gui, Map<String, Object> state) {
    }

    private static final Map<String, GuiModel> GUIS = new ConcurrentHashMap<>();
    private static final Map<UUID, GuiSession> SESSIONS = new ConcurrentHashMap<>();
    private static final Map<UUID, Deque<NavEntry>> NAV = new ConcurrentHashMap<>();
    private static volatile boolean initialized;

    private GuiRuntime() {
    }

    /**
     * Register the inventory/packet/disconnect listeners; call once after
     * MinecraftServer.init()
     */
    public static void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        GlobalEventHandler handler = MinecraftServer.getGlobalEventHandler();
        handler.addListener(InventoryPreClickEvent.class, GuiRuntime::onPreClick);
        handler.addListener(InventoryCloseEvent.class, GuiRuntime::onInventoryClose);
        handler.addListener(PlayerPacketEvent.class, event -> {
            if (event.getPacket() instanceof ClientUpdateSignPacket packet) {
                SignPrompt.onSignUpdate(event.getPlayer(), packet);
            }
        });
        handler.addListener(PlayerDisconnectEvent.class, event -> onDisconnect(event.getPlayer()));
    }

    /**
     * Register a gui declaration loaded from a script
     */
    public static void register(GuiModel gui) {
        if (gui.rows() < 1 || gui.rows() > 6) {
            throw new IllegalArgumentException("gui '" + gui.name() + "' rows must be 1-6");
        }
        GUIS.put(gui.name(), gui);
    }

    /**
     * open gui "name" to player [with { ... }] — pushes the nav stack
     */
    public static void openGui(Player player, String guiName, Map<String, Object> initialState) {
        GuiModel model = lookup(guiName);
        TickDispatch.call(() -> {
            GuiSession current = SESSIONS.remove(player.getUuid());
            if (current != null) {
                navStack(player).push(new NavEntry(current.modelName(), current.stateCopy()));
                current.close(GuiSession.CloseReason.REPLACED);
            }
            openInternal(player, model, initialState);
            return null;
        });
    }

    /**
     * replace gui "name" ... — switches without stacking
     */
    public static void replaceGui(Player player, String guiName, Map<String, Object> initialState) {
        GuiModel model = lookup(guiName);
        TickDispatch.call(() -> {
            GuiSession current = SESSIONS.remove(player.getUuid());
            if (current != null) {
                current.close(GuiSession.CloseReason.REPLACED);
            }
            openInternal(player, model, initialState);
            return null;
        });
    }

    /**
     * close gui for player — clears the nav stack; session teardown runs in
     * the InventoryCloseEvent listener
     */
    public static void closeGui(Player player) {
        TickDispatch.call(() -> {
            NAV.remove(player.getUuid());
            player.closeInventory();
            return null;
        });
    }

    /**
     * go back for player — pops the nav stack with its saved state, closes
     * when the stack is empty
     */
    public static void goBack(Player player) {
        TickDispatch.call(() -> {
            Deque<NavEntry> stack = NAV.get(player.getUuid());
            NavEntry previous = stack != null ? stack.poll() : null;
            if (previous == null) {
                NAV.remove(player.getUuid());
                player.closeInventory();
                return null;
            }
            GuiSession current = SESSIONS.remove(player.getUuid());
            if (current != null) {
                current.close(GuiSession.CloseReason.REPLACED);
            }
            openInternal(player, lookup(previous.gui()), previous.state());
            return null;
        });
    }

    /**
     * prompt_input(player, placeholder) builtin — ASYNC-ONLY; blocks the
     * calling virtual thread until the player submits the sign
     */
    public static String promptInput(Player player, String placeholder) {
        if (Thread.currentThread() instanceof TickThread
                || Thread.currentThread() instanceof TickSchedulerThread) {
            throw new ScriptError("prompt_input is async-only; call it from an async "
                    + "function, async block, or spawned task");
        }
        CompletableFuture<String> future =
                TickDispatch.call(() -> SignPrompt.open(player, placeholder));
        try {
            return future.get();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            SignPrompt.cancel(player);
            throw new HaltSignal();
        } catch (ExecutionException e) {
            Throwable cause = e.getCause();
            if (cause instanceof RuntimeException runtime) {
                throw runtime;
            }
            throw new RuntimeException(cause);
        }
    }

    private static void openInternal(Player player, GuiModel model, Map<String, Object> overrides) {
        Map<String, Object> stateValues = new LinkedHashMap<>();
        Map<String, Object> vars = new HashMap<>();
        vars.put("player", player);
        ASTExecutor executor = new ASTExecutor(player, vars);
        for (Map.Entry<String, Expression> entry : model.state().entrySet()) {
            stateValues.put(entry.getKey(), executor.evaluateExpression(entry.getValue()));
        }
        if (overrides != null) {
            stateValues.putAll(overrides);
        }
        GuiSession session = new GuiSession(player, model, stateValues);
        SESSIONS.put(player.getUuid(), session);
        session.open();
    }

    private static void onPreClick(InventoryPreClickEvent event) {
        GuiSession session = SESSIONS.get(event.getPlayer().getUuid());
        if (session == null || event.getPlayer().getOpenInventory() != session.inventory()) {
            return;
        }
        session.onPreClick(event);
    }

    /**
     * ESC or programmatic close: player_exited clears the whole nav stack
     */
    private static void onInventoryClose(InventoryCloseEvent event) {
        UUID uuid = event.getPlayer().getUuid();
        GuiSession session = SESSIONS.get(uuid);
        if (session == null || event.getInventory() != session.inventory()) {
            return;
        }
        SESSIONS.remove(uuid);
        NAV.remove(uuid);
        session.close(event.isFromClient()
                ? GuiSession.CloseReason.PLAYER_EXITED
                : GuiSession.CloseReason.SERVER_EXITED);
        // The on_close handler may have opened a new gui; Player.closeInventory
        // nulls its openInventory after this listener returns, so hand the new
        // inventory back through the event or the server would forget it
        GuiSession reopened = SESSIONS.get(uuid);
        if (reopened != null) {
            event.setNewInventory(reopened.inventory());
        }
    }

    private static void onDisconnect(Player player) {
        SignPrompt.cancel(player);
        NAV.remove(player.getUuid());
        GuiSession session = SESSIONS.remove(player.getUuid());
        if (session != null) {
            session.close(GuiSession.CloseReason.PLAYER_EXITED);
        }
    }

    private static GuiModel lookup(String name) {
        GuiModel model = GUIS.get(name);
        if (model == null) {
            throw new ScriptError("unknown gui '" + name + "'");
        }
        return model;
    }

    private static Deque<NavEntry> navStack(Player player) {
        return NAV.computeIfAbsent(player.getUuid(), uuid -> new ArrayDeque<>());
    }
}
