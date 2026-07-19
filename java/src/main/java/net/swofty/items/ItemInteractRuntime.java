package net.swofty.items;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.PlayerHand;
import net.minestom.server.event.EventDispatcher;
import net.minestom.server.event.GlobalEventHandler;
import net.minestom.server.event.player.PlayerBlockInteractEvent;
import net.minestom.server.event.player.PlayerDisconnectEvent;
import net.minestom.server.event.player.PlayerHandAnimationEvent;
import net.minestom.server.event.player.PlayerUseItemEvent;
import net.minestom.server.event.player.PlayerUseItemOnBlockEvent;
import net.minestom.server.event.trait.CancellableEvent;
import net.minestom.server.item.ItemStack;
import net.swofty.ASTExecutor;
import net.swofty.event.events.SwoftPlayerUseItemEvent;
import net.swofty.items.event.PlayerUseCustomItemEvent;
import net.swofty.model.ItemClickHandlerModel;
import net.swofty.model.ItemDefModel;

/**
 * Custom-item interaction dispatch (phase 9). The engine keeps the two
 * generic interaction surfaces — the PlayerUseItem wrapper event fires for
 * every custom-item interact, and per-item on_click(left|right|any)
 * handlers dispatch from the SAME path filtered by custom_id and click
 * side — but the Hypixel ability machinery (named abilities, cooldowns,
 * activation chips) is gone: scripters build those in userland with
 * on_click + tags, or with the abilities.sw stdlib addon. Handler mutations
 * of 'item' (set item.tags.x ...) flush back to the originating hand slot.
 */
public final class ItemInteractRuntime {
    /** (player uuid) -> last right-click dispatch key (tick << 1 | hand). */
    private static final Map<java.util.UUID, Long> LAST_RIGHT_CLICK =
            new ConcurrentHashMap<>();
    private static boolean initialized = false;

    private ItemInteractRuntime() {
    }

    public static synchronized void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        GlobalEventHandler handler = MinecraftServer.getGlobalEventHandler();
        // right-click on air
        handler.addListener(PlayerUseItemEvent.class, event ->
                handleRightClick(event.getPlayer(), event.getItemStack(), event.getHand(),
                        event));
        // right-click with a block targeted: BlockPlacementListener fires
        // PlayerBlockInteractEvent (always, item read from the hand) and
        // PlayerUseItemOnBlockEvent (non-block items only, not cancellable)
        handler.addListener(PlayerBlockInteractEvent.class, event ->
                handleRightClick(event.getPlayer(),
                        event.getPlayer().getItemInHand(event.getHand()), event.getHand(),
                        event));
        handler.addListener(PlayerUseItemOnBlockEvent.class, event ->
                handleRightClick(event.getPlayer(), event.getItemStack(), event.getHand(),
                        null));
        handler.addListener(PlayerHandAnimationEvent.class, event ->
                handleInteract(event.getPlayer(),
                        event.getPlayer().getItemInHand(event.getHand()),
                        "left_click", event.getHand(), event));
        handler.addListener(PlayerDisconnectEvent.class, event ->
                LAST_RIGHT_CLICK.remove(event.getPlayer().getUuid()));
    }

    /**
     * One physical right click can emit several Minestom events (a
     * use-on-block fires PlayerBlockInteractEvent AND
     * PlayerUseItemOnBlockEvent): collapse them per player+hand+tick before
     * dispatching.
     */
    private static void handleRightClick(Player player, ItemStack stack, PlayerHand hand,
            CancellableEvent minestomEvent) {
        long key = (player.getAliveTicks() << 1) | (hand == PlayerHand.OFF ? 1L : 0L);
        Long previous = LAST_RIGHT_CLICK.put(player.getUuid(), key);
        if (previous != null && previous == key) {
            return;
        }
        handleInteract(player, stack, "right_click", hand, minestomEvent);
    }

    private static void handleInteract(Player player, ItemStack stack, String activation,
            PlayerHand hand, CancellableEvent minestomEvent) {
        String id = ItemRegistry.customId(stack);
        if (id == null) {
            return;
        }
        ItemDefModel def = ItemRegistry.get(id);
        if (def == null) {
            return;
        }

        // PlayerUseItem wrapper event - fires for every custom-item interact
        PlayerUseCustomItemEvent useEvent =
                new PlayerUseCustomItemEvent(player, stack, id, activation, hand);
        EventDispatcher.call(useEvent);
        if (useEvent.isCancelled()) {
            if (minestomEvent != null) {
                minestomEvent.setCancelled(true);
            }
            return;
        }

        // on_click(<filter>) sugar: run the matching per-item handlers on
        // the same path, binding player + item, cancellable via cancel event
        List<ItemClickHandlerModel> handlers = def.onClick();
        if (handlers == null || handlers.isEmpty()) {
            return;
        }
        Map<String, Object> variables = new HashMap<>();
        variables.put("player", player);
        variables.put("item", stack);
        variables.put("item_id", id);
        SwoftPlayerUseItemEvent wrapper = new SwoftPlayerUseItemEvent(useEvent, null);
        variables.put("event", wrapper);
        boolean ran = false;
        for (ItemClickHandlerModel handler : handlers) {
            if (!filterMatches(handler.filter(), activation)) {
                continue;
            }
            ran = true;
            try {
                new ASTExecutor(player, variables).execute(handler.body());
            } catch (Exception e) {
                System.err.println("Error running on_click handler of item '" + id + "': "
                        + e.getMessage());
            }
            if (wrapper.isCancelled()) {
                break;
            }
        }
        if (!ran) {
            return;
        }
        if (wrapper.isCancelled() && minestomEvent != null) {
            minestomEvent.setCancelled(true);
        }
        // 'set item.tags.x' rebinds the LOCAL 'item' variable to a fresh
        // re-rendered stack: flush that rebind back to the originating slot
        flushItemRebind(player, hand, stack, variables.get("item"));
    }

    /** left|right|any filter against the "left_click"/"right_click" side. */
    private static boolean filterMatches(String filter, String activation) {
        return switch (filter) {
            case "any" -> true;
            case "right" -> activation.equals("right_click");
            case "left" -> activation.equals("left_click");
            default -> false;
        };
    }

    /**
     * Compare-and-set write-back for the 'item' binding of interact
     * handlers: if the handler rebound 'item' to a different stack and the
     * originating slot still holds the stack captured at dispatch, replace
     * it. A handler that already swapped the held item itself wins.
     */
    public static void flushItemRebind(Player player, PlayerHand hand, ItemStack original,
            Object rebound) {
        if (!(rebound instanceof ItemStack updated) || updated.equals(original)) {
            return;
        }
        if (player.getItemInHand(hand).equals(original)) {
            player.setItemInHand(hand, updated);
        }
    }
}
