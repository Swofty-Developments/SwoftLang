package net.swofty.fishing;

import java.util.concurrent.atomic.AtomicInteger;

import net.minestom.server.entity.Player;

/**
 * One player's live cast (phase 8): the bobber, the bite state, and a
 * generation counter that invalidates scheduled bite/expiry callbacks
 * (TickClock futures cannot be cancelled, so stale generations no-op).
 */
public final class FishingSession {
    private final Player player;
    private final FishingBobber bobber;
    private final long castAtMillis = System.currentTimeMillis();
    private final AtomicInteger generation = new AtomicInteger();
    private volatile boolean biteReady;

    public FishingSession(Player player, FishingBobber bobber) {
        this.player = player;
        this.bobber = bobber;
    }

    public Player player() {
        return player;
    }

    public FishingBobber bobber() {
        return bobber;
    }

    public long castAtMillis() {
        return castAtMillis;
    }

    public boolean isBiteReady() {
        return biteReady;
    }

    public void setBiteReady(boolean biteReady) {
        this.biteReady = biteReady;
    }

    /** Invalidate pending callbacks and start a new schedule generation. */
    public int nextGeneration() {
        biteReady = false;
        return generation.incrementAndGet();
    }

    public boolean isCurrent(int expected) {
        return generation.get() == expected;
    }

    /** Terminal invalidation: no scheduled callback can act anymore. */
    public void invalidate() {
        nextGeneration();
    }
}
