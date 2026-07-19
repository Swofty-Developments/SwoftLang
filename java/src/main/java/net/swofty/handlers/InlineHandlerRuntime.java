package net.swofty.handlers;

import net.minestom.server.MinecraftServer;
import net.minestom.server.component.DataComponents;
import net.minestom.server.coordinate.Point;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.PlayerHand;
import net.minestom.server.event.GlobalEventHandler;
import net.minestom.server.event.entity.EntityAttackEvent;
import net.minestom.server.event.item.ItemDropEvent;
import net.minestom.server.event.item.PickupItemEvent;
import net.minestom.server.event.item.PlayerFinishItemUseEvent;
import net.minestom.server.event.player.PlayerChangeHeldSlotEvent;
import net.minestom.server.event.player.PlayerEntityInteractEvent;
import net.minestom.server.event.player.PlayerHandAnimationEvent;
import net.minestom.server.event.player.PlayerUseItemEvent;
import net.minestom.server.event.player.PlayerUseItemOnBlockEvent;
import net.minestom.server.item.ItemStack;
import net.swofty.holograms.HologramRuntime;
import net.swofty.items.ItemRegistry;
import net.swofty.mobs.SwoftMob;
import net.swofty.model.HologramModel;
import net.swofty.model.InlineHandler;
import net.swofty.model.ItemDefModel;
import net.swofty.props.NoneValue;

/**
 * The single filtered dispatcher per (kind, event) for first-class inline
 * handlers (W-inline-handlers). It generalizes the mob {@code on_hit} path
 * (SwoftMob.handleMeleeHit + runHandler, now routed through
 * {@link HandlerDispatch}) into one global listener per event that resolves the
 * involved declaration, filters it (mob type/id, item declaration id,
 * hologram name), and dispatches to that declaration's matching handler with
 * {@code this} + the event args bound.
 *
 * <p>Legacy dedicated handlers keep their existing wiring: mob
 * on_spawn/on_death/on_attack/on_hit fire from {@link SwoftMob} overrides, item
 * {@code on_click(left|right|any)} sugar from ItemInteractRuntime, and npc
 * on_click/on_left_click from NpcRuntime. This runtime owns only the additive
 * generic handler set the compiler emits under {@code "handlers"}:
 *
 * <ul>
 *   <li><b>MOB</b> — on_click (PlayerEntityInteract), on_target (AI target
 *       change, forwarded from {@code SwoftMob.setTarget}), on_tick (forwarded
 *       from {@code SwoftMob.tick}, only when declared).</li>
 *   <li><b>ITEM</b> — on_right_click (PlayerUseItem), on_right_click_block
 *       (UseItemOnBlock), on_left_click (HandAnimation), on_attack_entity
 *       (EntityAttack), on_consume (finish-use), on_drop (ItemDrop), on_pickup
 *       (PickupItem), on_swap_to (ChangeHeldSlot), on_break (native durability
 *       track).</li>
 *   <li><b>HOLOGRAM</b> — on_click via the interact packet.</li>
 * </ul>
 *
 * <p>Cancellable handlers (on_right_click / on_attack_entity / on_drop) let the
 * body {@code cancel} to veto through the underlying Minestom
 * {@code CancellableEvent}. Listeners are stateless and filter against the live
 * registries, so {@link #init} is idempotent and {@link #teardown} (the #58
 * hot-reload hook) has nothing per-instance to release.
 */
public final class InlineHandlerRuntime {

    private static boolean initialized = false;

    private InlineHandlerRuntime() {
    }

    // ------------------------------------------------------------------
    // one-time listener wiring
    // ------------------------------------------------------------------

    public static synchronized void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        GlobalEventHandler handler = MinecraftServer.getGlobalEventHandler();

        // ---- MOB on_click + HOLOGRAM on_click: right-click interact packet
        handler.addListener(PlayerEntityInteractEvent.class, event -> {
            if (event.getHand() != PlayerHand.MAIN) {
                return;
            }
            Entity target = event.getTarget();
            Player player = event.getPlayer();
            if (target instanceof SwoftMob mob) {
                dispatchMob(mob, "on_click", player);
                return;
            }
            String holo = HologramRuntime.holoNameForEntity(target.getEntityId());
            if (holo != null) {
                dispatchHologram(holo, "on_click", player);
            }
        });

        // ---- ITEM on_right_click: right-click air (cancellable)
        handler.addListener(PlayerUseItemEvent.class, event ->
                dispatchItem(event.getItemStack(), "on_right_click", event,
                        event.getPlayer()));

        // ---- ITEM on_right_click_block: right-click a block (not cancellable)
        handler.addListener(PlayerUseItemOnBlockEvent.class, event -> {
            Point at = event.getPosition();
            ItemDefModel def = dispatchItem(event.getItemStack(), "on_right_click_block", null,
                    event.getPlayer(), new Pos(at.x(), at.y(), at.z()),
                    event.getBlockFace().name());
            if (def != null) {
                trackDurability(event.getPlayer(), event.getHand(), event.getItemStack(), def);
            }
        });

        // ---- ITEM on_left_click: left-click air/block
        handler.addListener(PlayerHandAnimationEvent.class, event -> {
            Player player = event.getPlayer();
            dispatchItem(player.getItemInHand(event.getHand()), "on_left_click", null, player);
        });

        // ---- ITEM on_attack_entity: hit an entity while holding it
        handler.addListener(EntityAttackEvent.class, event -> {
            if (!(event.getEntity() instanceof Player player)) {
                return;
            }
            ItemStack stack = player.getItemInHand(PlayerHand.MAIN);
            ItemDefModel def = dispatchItem(stack, "on_attack_entity", null, player,
                    event.getTarget());
            if (def != null) {
                trackDurability(player, PlayerHand.MAIN, stack, def);
            }
        });

        // ---- ITEM on_consume: finished eating/drinking
        handler.addListener(PlayerFinishItemUseEvent.class, event ->
                dispatchItem(event.getItemStack(), "on_consume", null, event.getPlayer()));

        // ---- ITEM on_drop: dropped (cancellable)
        handler.addListener(ItemDropEvent.class, event ->
                dispatchItem(event.getItemStack(), "on_drop", event, event.getPlayer()));

        // ---- ITEM on_pickup: picked up
        handler.addListener(PickupItemEvent.class, event -> {
            if (event.getLivingEntity() instanceof Player player) {
                dispatchItem(event.getItemStack(), "on_pickup", null, player);
            }
        });

        // ---- ITEM on_swap_to: became the held item
        handler.addListener(PlayerChangeHeldSlotEvent.class, event ->
                dispatchItem(event.getItemInNewSlot(), "on_swap_to", null, event.getPlayer()));
    }

    /** Hot-reload teardown (#58): stateless global listeners, nothing to drop. */
    public static void teardown() {
        // Listeners resolve declarations from the live registries on each
        // event, so a reload that swaps the registries automatically retargets
        // them; there is no per-declaration listener state to release.
    }

    // ------------------------------------------------------------------
    // per-kind dispatch (filtered)
    // ------------------------------------------------------------------

    /**
     * Fire a mob's generic handler for {@code event} (on_click / on_target /
     * on_tick). {@code this} binds to the mob entity; null args (a lost AI
     * target) bind as {@code none}. Non-cancellable.
     */
    public static void dispatchMob(SwoftMob mob, String event, Object... args) {
        InlineHandler handler = mob.getDef().handler(event);
        if (handler == null) {
            return;
        }
        HandlerDispatch.dispatch(handler, mob, null,
                "mob '" + mob.getDef().id() + "' " + event, normalize(args));
    }

    /**
     * Resolve the acted stack to its declaration and fire {@code event},
     * binding {@code this} = the ItemStack + the event args. Returns the
     * declaration when a handler ran (so the caller can apply durability), else
     * null. A cancellable Minestom event is passed through so the body's
     * {@code cancel} vetoes.
     */
    private static ItemDefModel dispatchItem(ItemStack stack, String event,
            net.minestom.server.event.Event cancellable, Object... args) {
        if (stack == null || stack.isAir()) {
            return null;
        }
        String id = ItemRegistry.customId(stack);
        if (id == null) {
            return null;
        }
        ItemDefModel def = ItemRegistry.get(id);
        if (def == null) {
            return null;
        }
        InlineHandler handler = def.handler(event);
        if (handler == null) {
            return null;
        }
        HandlerDispatch.dispatch(handler, stack, cancellable,
                "item '" + id + "' " + event, args);
        return def;
    }

    private static void dispatchHologram(String name, String event, Player player) {
        HologramModel model = HologramRuntime.modelFor(name);
        if (model == null) {
            return;
        }
        InlineHandler handler = model.handler(event);
        if (handler == null) {
            return;
        }
        HandlerDispatch.dispatch(handler, name, null,
                "hologram '" + name + "' " + event, player);
    }

    // ------------------------------------------------------------------
    // on_break: native durability track (only for items that declare it)
    // ------------------------------------------------------------------

    /**
     * Apply one point of native durability to a damageable stack that declares
     * an {@code on_break} handler; when the damage reaches the item's max the
     * stack is consumed and {@code on_break} fires with {@code this} = the
     * broken stack. Undamageable items (no MAX_DAMAGE component) are untouched.
     */
    private static void trackDurability(Player player, PlayerHand hand, ItemStack stack,
            ItemDefModel def) {
        InlineHandler onBreak = def.handler("on_break");
        if (onBreak == null) {
            return;
        }
        Integer max = stack.get(DataComponents.MAX_DAMAGE);
        if (max == null || max <= 0) {
            return;
        }
        int damage = stack.get(DataComponents.DAMAGE, 0) + 1;
        if (damage >= max) {
            player.setItemInHand(hand, ItemStack.AIR);
            HandlerDispatch.dispatch(onBreak, stack, null,
                    "item '" + ItemRegistry.customId(stack) + "' on_break", player);
        } else {
            player.setItemInHand(hand, stack.with(DataComponents.DAMAGE, damage));
        }
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    /** Null args bind as {@code none} so optional<Entity> params stay valid. */
    private static Object[] normalize(Object[] args) {
        Object[] out = new Object[args.length];
        for (int i = 0; i < args.length; i++) {
            out[i] = args[i] == null ? NoneValue.INSTANCE : args[i];
        }
        return out;
    }
}
