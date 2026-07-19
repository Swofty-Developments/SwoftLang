package net.swofty.fishing;

import java.time.Duration;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadLocalRandom;

import net.kyori.adventure.sound.Sound;
import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.coordinate.Vec;
import net.minestom.server.entity.ItemEntity;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.PlayerHand;
import net.minestom.server.event.EventDispatcher;
import net.minestom.server.event.GlobalEventHandler;
import net.minestom.server.event.player.PlayerBlockInteractEvent;
import net.minestom.server.event.player.PlayerDisconnectEvent;
import net.minestom.server.event.player.PlayerUseItemEvent;
import net.minestom.server.event.player.PlayerUseItemOnBlockEvent;
import net.minestom.server.instance.Instance;
import net.minestom.server.item.ItemStack;
import net.minestom.server.item.Material;
import net.minestom.server.sound.SoundEvent;
import net.swofty.InstanceRegistry;
import net.swofty.TextFormat;
import net.swofty.async.TickClock;
import net.swofty.fishing.event.FishBiteEvent;
import net.swofty.fishing.event.PlayerCastRodEvent;
import net.swofty.fishing.event.PlayerCatchFishEvent;
import net.swofty.fishing.event.PlayerReelInEvent;
import net.swofty.items.ItemRegistry;
import net.swofty.mobs.MobRegistry;
import net.swofty.mobs.SwoftMob;
import net.swofty.model.FishingLootEntryModel;
import net.swofty.model.FishingLootModel;
import net.swofty.model.ServerConfigModel;

/**
 * The native fishing engine (phase 8): rod-use detection over the same
 * interact events as the item-ability path (deduplicated per
 * player+hand+tick), one FishingSession per player, bite scheduling on
 * the TickClock inside a randomized server-configured window, and
 * weighted loot resolution on reel-during-bite. Item catches fly to the
 * fisher (ItemEntity velocity toward the eyes, SkyBlock-style); mob
 * catches spawn the registry mob at the hook and aggro the fisher. The
 * four typed events fire at their contract points: PlayerCastRod
 * (cancellable, pre-bobber), FishBite (at the bite), PlayerCatchFish
 * (pre-delivery, caught_item swappable, cancellable), PlayerReelIn
 * (every reel).
 */
public final class FishingRuntime {
    public static final int DEFAULT_MIN_BITE_TICKS = 100;  // 5s
    public static final int DEFAULT_MAX_BITE_TICKS = 600;  // 30s
    private static final int BITE_WINDOW_TICKS = 30;
    private static final long PICKUP_DELAY_MILLIS = 500;

    private static final Map<UUID, FishingSession> SESSIONS = new ConcurrentHashMap<>();
    /** (player uuid) -> last rod-use dispatch key (tick << 1 | hand). */
    private static final Map<UUID, Long> LAST_ROD_USE = new ConcurrentHashMap<>();
    private static volatile int minBiteTicks = DEFAULT_MIN_BITE_TICKS;
    private static volatile int maxBiteTicks = DEFAULT_MAX_BITE_TICKS;
    private static boolean initialized = false;

    private FishingRuntime() {
    }

    public static synchronized void init(ServerConfigModel config) {
        configure(config);
        if (initialized) {
            return;
        }
        initialized = true;
        GlobalEventHandler handler = MinecraftServer.getGlobalEventHandler();
        // the same three right-click shapes the ability runtime listens on:
        // air, block-targeted interact, and use-on-block
        handler.addListener(PlayerUseItemEvent.class, event ->
                handleRodUse(event.getPlayer(), event.getItemStack(), event.getHand()));
        handler.addListener(PlayerBlockInteractEvent.class, event ->
                handleRodUse(event.getPlayer(),
                        event.getPlayer().getItemInHand(event.getHand()), event.getHand()));
        handler.addListener(PlayerUseItemOnBlockEvent.class, event ->
                handleRodUse(event.getPlayer(), event.getItemStack(), event.getHand()));
        handler.addListener(PlayerDisconnectEvent.class, event -> {
            clearSession(event.getPlayer().getUuid());
            LAST_ROD_USE.remove(event.getPlayer().getUuid());
        });
    }

    /** Apply server{} fishing { min_bite / max_bite } (ticks). */
    public static void configure(ServerConfigModel config) {
        int min = config != null ? config.fishingMinBiteTicks() : DEFAULT_MIN_BITE_TICKS;
        int max = config != null ? config.fishingMaxBiteTicks() : DEFAULT_MAX_BITE_TICKS;
        if (min <= 0) {
            min = DEFAULT_MIN_BITE_TICKS;
        }
        if (max <= 0) {
            max = DEFAULT_MAX_BITE_TICKS;
        }
        if (max < min) {
            System.err.println("Warning: fishing max_bite < min_bite - swapping");
            int tmp = min;
            min = max;
            max = tmp;
        }
        minBiteTicks = min;
        maxBiteTicks = max;
    }

    // ------------------------------------------------------------------
    // cast / reel
    // ------------------------------------------------------------------

    private static void handleRodUse(Player player, ItemStack stack, PlayerHand hand) {
        if (stack.material() != Material.FISHING_ROD) {
            return;
        }
        // one physical right click can emit several Minestom events:
        // collapse per player+hand+tick (same scheme as the ability path)
        long key = (player.getAliveTicks() << 1) | (hand == PlayerHand.OFF ? 1L : 0L);
        Long previous = LAST_ROD_USE.put(player.getUuid(), key);
        if (previous != null && previous == key) {
            return;
        }

        FishingSession session = SESSIONS.get(player.getUuid());
        if (session != null) {
            reel(player, session);
        } else {
            cast(player);
        }
    }

    private static void cast(Player player) {
        Instance instance = player.getInstance();
        if (instance == null) {
            return;
        }
        PlayerCastRodEvent castEvent = new PlayerCastRodEvent(player);
        EventDispatcher.call(castEvent);
        if (castEvent.isCancelled()) {
            return;
        }
        FishingBobber bobber = new FishingBobber(player);
        SESSIONS.put(player.getUuid(), new FishingSession(player, bobber));
        bobber.spawn(instance);
    }

    private static void reel(Player player, FishingSession session) {
        // read the bite state BEFORE invalidating: invalidate() clears
        // biteReady as part of killing the scheduled callbacks
        boolean bite = session.isBiteReady();
        SESSIONS.remove(player.getUuid(), session);
        session.invalidate();
        Pos hookPos = session.bobber().position();
        Instance instance = session.bobber().instance();
        FishingMedium medium = session.bobber().medium();
        session.bobber().remove();

        player.playSound(Sound.sound(SoundEvent.ENTITY_FISHING_BOBBER_RETRIEVE.key(),
                Sound.Source.NEUTRAL, 1f, 1f), Sound.Emitter.self());
        EventDispatcher.call(new PlayerReelInEvent(player));

        if (bite && medium != null && instance != null) {
            resolveCatch(player, medium, instance, hookPos);
        }
    }

    /** Bobber tick lost its preconditions (owner left/world change/no rod). */
    static void abandon(Player player) {
        clearSession(player.getUuid());
    }

    public static void clearSession(UUID playerUuid) {
        FishingSession session = SESSIONS.remove(playerUuid);
        if (session != null) {
            session.invalidate();
            session.bobber().remove();
        }
    }

    /** Reload/shutdown: reel nothing, remove every bobber and session. */
    public static void reset() {
        for (UUID uuid : SESSIONS.keySet()) {
            clearSession(uuid);
        }
        LAST_ROD_USE.clear();
    }

    /** Live session for a player (harness introspection), or null. */
    public static FishingSession session(UUID playerUuid) {
        return SESSIONS.get(playerUuid);
    }

    // ------------------------------------------------------------------
    // bite scheduling (TickClock)
    // ------------------------------------------------------------------

    static void onBobberSettled(Player owner, FishingMedium medium) {
        FishingSession session = SESSIONS.get(owner.getUuid());
        if (session == null) {
            return;
        }
        scheduleBite(session);
    }

    static void onBobberUnsettled(Player owner) {
        FishingSession session = SESSIONS.get(owner.getUuid());
        if (session != null) {
            // cancel the pending bite; a re-settle re-arms
            session.nextGeneration();
        }
    }

    private static void scheduleBite(FishingSession session) {
        int generation = session.nextGeneration();
        TickClock.after(rollBiteDelayTicks(minBiteTicks, maxBiteTicks))
                .thenRun(() -> onBiteDue(session, generation));
    }

    private static void onBiteDue(FishingSession session, int generation) {
        if (!session.isCurrent(generation) || session.bobber().isRemoved()
                || session.bobber().medium() == null
                || SESSIONS.get(session.player().getUuid()) != session) {
            return;
        }
        session.setBiteReady(true);
        session.bobber().showBite();
        EventDispatcher.call(new FishBiteEvent(session.player(),
                session.bobber().position()));
        TickClock.after(BITE_WINDOW_TICKS).thenRun(() -> {
            if (!session.isCurrent(generation) || !session.isBiteReady()
                    || SESSIONS.get(session.player().getUuid()) != session) {
                return;
            }
            // window missed: re-arm a fresh randomized wait
            scheduleBite(session);
        });
    }

    /** Uniform randomized bite delay within [min, max] ticks. */
    public static long rollBiteDelayTicks(int min, int max) {
        if (max <= min) {
            return min;
        }
        return ThreadLocalRandom.current().nextLong(min, max + 1L);
    }

    public static int minBiteTicks() {
        return minBiteTicks;
    }

    public static int maxBiteTicks() {
        return maxBiteTicks;
    }

    // ------------------------------------------------------------------
    // catch resolution
    // ------------------------------------------------------------------

    private static void resolveCatch(Player player, FishingMedium medium,
            Instance instance, Pos hookPos) {
        FishingLootModel table = FishingLootRegistry.match(medium,
                InstanceRegistry.nameOf(instance));
        FishingLootEntryModel entry = FishingLootRegistry.roll(table.entries(),
                ThreadLocalRandom.current());
        if (entry == null) {
            return;
        }

        ItemStack stack = null;
        SwoftMob mob = null;
        if (entry.kind().equals("mob")) {
            if (MobRegistry.get(entry.id()) == null) {
                System.err.println("Warning: fishing_loot '" + table.name()
                        + "' catch mob '" + entry.id() + "' is not a registered mob");
                return;
            }
            // constructed now so handlers see the real Mob value, but it
            // only enters the world after the event (cancel discards it)
            mob = new SwoftMob(MobRegistry.get(entry.id()));
        } else {
            stack = buildStack(table.name(), entry.id());
            if (stack == null) {
                return;
            }
        }

        PlayerCatchFishEvent catchEvent =
                new PlayerCatchFishEvent(player, stack, mob, hookPos);
        EventDispatcher.call(catchEvent);
        if (catchEvent.isCancelled()) {
            return;
        }

        if (mob != null) {
            mob.setInstance(instance, hookPos);
            mob.setTarget(player); // sea-creature behavior: aggro the fisher
        } else {
            ItemStack delivered = catchEvent.getCaughtItem();
            if (delivered != null && !delivered.isAir()) {
                flyToPlayer(player, instance, hookPos, delivered);
            }
        }
        if (entry.message() != null && !entry.message().isBlank()) {
            player.sendMessage(TextFormat.component(entry.message()));
        }
    }

    /** Item catches fly from the hook toward the fisher's eyes. */
    private static void flyToPlayer(Player player, Instance instance, Pos hookPos,
            ItemStack stack) {
        ItemEntity itemEntity = new ItemEntity(stack);
        itemEntity.setPickupDelay(Duration.ofMillis(PICKUP_DELAY_MILLIS));
        itemEntity.setInstance(instance, hookPos);
        Pos eye = player.getPosition().add(0, player.getEyeHeight(), 0);
        Vec delta = eye.sub(hookPos).asVec();
        // blocks/second: cover the distance quickly with a lift that grows
        // slightly with range so the arc clears the water lip
        Vec velocity = delta.mul(2.0).add(0, 1.5 + delta.length() * 0.1, 0);
        itemEntity.setVelocity(velocity);
    }

    /** Custom item registry id first, vanilla material fallback. */
    private static ItemStack buildStack(String tableName, String id) {
        if (ItemRegistry.get(id) != null) {
            return ItemRegistry.build(id, 1);
        }
        Material material = Material.fromKey(id.contains(":")
                ? id.toLowerCase() : "minecraft:" + id.toLowerCase());
        if (material == null) {
            System.err.println("Warning: fishing_loot '" + tableName + "' catch item '"
                    + id + "' is neither a custom item nor a material");
            return null;
        }
        return ItemStack.of(material);
    }
}
