package net.swofty.fishing;

import net.kyori.adventure.sound.Sound;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.EntityType;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.metadata.other.FishingHookMeta;
import net.minestom.server.event.entity.EntityTickEvent;
import net.minestom.server.instance.Instance;
import net.minestom.server.instance.block.Block;
import net.minestom.server.item.Material;
import net.minestom.server.network.packet.server.play.ParticlePacket;
import net.minestom.server.particle.Particle;
import net.minestom.server.sound.SoundEvent;
import net.swofty.entities.ScriptEntityRegistry;

/**
 * The cast bobber (phase 8), physics ported from the SkyBlock
 * FishingHook approach: the visible FISHING_BOBBER (FishingHookMeta with
 * the owner set so the client draws the line) rides an invisible
 * text-display "controller" that owns the movement — throw velocity from
 * the caster's look direction, gravity until a fishable liquid is found,
 * then a surface settle with a sine bob and a bite pull-down. Both
 * entities are tracked in the phase-7 script entity registry so
 * reload/shutdown sweeps reclaim them.
 */
public final class FishingBobber {
    private static final double THROW_SPEED = 10.0;
    private static final double BOB_SPEED = 0.1;
    private static final double BOB_AMOUNT = 0.09;
    private static final double SURFACE_OFFSET = -0.02;
    private static final double MAX_PULL_DOWN = 0.3;
    private static final double PULL_DOWN_RECOVERY = 1.0 / 60.0;
    private static final double CONTROLLER_DRAG = 0.2;
    private static final double LIQUID_CHECK_OFFSET = -0.2;

    private final Player owner;
    private final Entity hook;
    private final Entity controller;
    private volatile boolean removed;
    private volatile FishingMedium settledMedium;
    private double bobTick;
    private double pullDownOffset;
    private Double surfaceY;

    public FishingBobber(Player owner) {
        this.owner = owner;
        this.hook = new Entity(EntityType.FISHING_BOBBER);
        this.hook.editEntityMeta(FishingHookMeta.class, meta -> meta.setOwnerEntity(owner));
        this.controller = new Entity(EntityType.TEXT_DISPLAY);
        this.controller.setNoGravity(true);
        this.controller.eventNode().addListener(EntityTickEvent.class, event -> tick());
    }

    /** Throw the bobber from the owner's eyes along the look direction. */
    public void spawn(Instance instance) {
        Pos eye = owner.getPosition().add(0, owner.getEyeHeight(), 0);
        controller.setInstance(instance, eye);
        hook.setInstance(instance, eye);
        controller.addPassenger(hook);
        controller.setVelocity(owner.getPosition().direction().mul(THROW_SPEED));
        ScriptEntityRegistry.track(hook);
        ScriptEntityRegistry.track(controller);
        float pitch = 1f / 3f + (float) (Math.random() * (0.5 - 1.0 / 3.0));
        owner.playSound(Sound.sound(SoundEvent.ENTITY_FISHING_BOBBER_THROW.key(),
                Sound.Source.NEUTRAL, 0.5f, pitch), Sound.Emitter.self());
    }

    private void tick() {
        if (removed) {
            return;
        }
        Instance instance = controller.getInstance();
        if (instance == null) {
            return;
        }
        if (!shouldKeepExisting(instance)) {
            FishingRuntime.abandon(owner);
            return;
        }

        Pos pos = controller.getPosition();
        FishingMedium medium = mediumAt(instance, pos);
        if (medium == null) {
            if (settledMedium != null) {
                settledMedium = null;
                FishingRuntime.onBobberUnsettled(owner);
            }
            surfaceY = null;
            controller.setNoGravity(false); // keep falling / flying
            return;
        }

        controller.setNoGravity(true);
        if (surfaceY == null) {
            Block below = instance.getBlock(pos.add(0, LIQUID_CHECK_OFFSET, 0));
            surfaceY = liquidSurface(below,
                    (int) Math.floor(pos.y() + LIQUID_CHECK_OFFSET)) + SURFACE_OFFSET;
            bobTick = 0;
            pullDownOffset = 0;
            settledMedium = medium;
            splash(instance, 5, 0.25f, 0.8f);
            FishingRuntime.onBobberSettled(owner, medium);
        }

        bobTick += BOB_SPEED;
        double yBob = Math.sin(bobTick) * BOB_AMOUNT;
        pullDownOffset = Math.max(pullDownOffset - PULL_DOWN_RECOVERY, 0);
        controller.teleport(new Pos(pos.x(), surfaceY + yBob - pullDownOffset, pos.z()));
        controller.setVelocity(controller.getVelocity().mul(CONTROLLER_DRAG));
    }

    /** Bite feedback: dip the bobber, big splash, splash sound. */
    public void showBite() {
        Instance instance = controller.getInstance();
        if (instance == null) {
            return;
        }
        splash(instance, 20, 1f, 1f);
        pullDownOffset = Math.min(pullDownOffset + 0.15, MAX_PULL_DOWN);
        bobTick += Math.PI / 6;
    }

    private void splash(Instance instance, int count, float volume, float pitch) {
        Pos pos = controller.getPosition();
        instance.playSound(Sound.sound(SoundEvent.ENTITY_FISHING_BOBBER_SPLASH.key(),
                Sound.Source.PLAYER, volume, pitch), pos.x(), pos.y(), pos.z());
        instance.sendGroupedPacket(new ParticlePacket(Particle.SPLASH,
                pos.x(), pos.y(), pos.z(), 0.1f, 0.001f, 0.1f, 0f, count));
    }

    /** Owner still here, same world, rod still in either hand? */
    private boolean shouldKeepExisting(Instance instance) {
        if (owner.isRemoved() || owner.getInstance() != instance) {
            return false;
        }
        return owner.getItemInMainHand().material() == Material.FISHING_ROD
                || owner.getItemInOffHand().material() == Material.FISHING_ROD;
    }

    private static FishingMedium mediumAt(Instance instance, Pos pos) {
        FishingMedium at = FishingMedium.fromBlock(instance.getBlock(pos));
        if (at != null) {
            return at;
        }
        return FishingMedium.fromBlock(instance.getBlock(
                pos.add(0, LIQUID_CHECK_OFFSET, 0)));
    }

    /** Liquid level property -> the visible surface height. */
    private static double liquidSurface(Block block, int blockY) {
        if (!block.isLiquid()) {
            return blockY + 1.0;
        }
        String levelProperty = block.getProperty("level");
        int level = levelProperty == null ? 0 : Integer.parseInt(levelProperty);
        return blockY + (level == 0 ? 1.0 : (8 - level) / 8.0);
    }

    public void remove() {
        if (removed) {
            return;
        }
        removed = true;
        ScriptEntityRegistry.untrack(hook);
        ScriptEntityRegistry.untrack(controller);
        hook.remove();
        controller.remove();
    }

    public boolean isRemoved() {
        return removed;
    }

    /** The medium the bobber is settled in, or null mid-flight. */
    public FishingMedium medium() {
        return settledMedium;
    }

    public Pos position() {
        return controller.getPosition();
    }

    public Instance instance() {
        return controller.getInstance();
    }

    public Player owner() {
        return owner;
    }
}
