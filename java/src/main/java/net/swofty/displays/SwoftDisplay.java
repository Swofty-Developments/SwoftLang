package net.swofty.displays;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import net.kyori.adventure.text.Component;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.coordinate.Vec;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.EntityType;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.metadata.display.AbstractDisplayMeta;
import net.minestom.server.entity.metadata.display.BlockDisplayMeta;
import net.minestom.server.entity.metadata.display.ItemDisplayMeta;
import net.minestom.server.entity.metadata.display.TextDisplayMeta;
import net.minestom.server.instance.Instance;
import net.minestom.server.instance.block.Block;
import net.minestom.server.item.ItemStack;
import net.swofty.ScriptError;
import net.swofty.TextFormat;
import net.swofty.async.TickDispatch;

/**
 * A real display entity (design 6B): Entity(EntityType.TEXT_DISPLAY /
 * ITEM_DISPLAY / BLOCK_DISPLAY) with the pinned display metas. Rotations
 * are euler degrees in the language and quaternions internally (the meta's
 * left rotation). Per-viewer visibility flips the entity into manual
 * viewer mode; groups are built by mounting displays on a shared anchor
 * entity (Minestom passenger mounting).
 */
public final class SwoftDisplay {
    public enum Kind {
        TEXT(EntityType.TEXT_DISPLAY),
        ITEM(EntityType.ITEM_DISPLAY),
        BLOCK(EntityType.BLOCK_DISPLAY);

        final EntityType entityType;

        Kind(EntityType entityType) {
            this.entityType = entityType;
        }
    }

    private final Kind kind;
    private final Entity entity;
    /** Euler degrees as last set through the rotation property. */
    private volatile double eulerX;
    private volatile double eulerY;
    private volatile double eulerZ;
    /** Players explicitly hidden/shown once the display left auto mode. */
    private final Set<Player> manualViewers = ConcurrentHashMap.newKeySet();
    private volatile boolean manualVisibility = false;
    private volatile boolean destroyed = false;

    public SwoftDisplay(Kind kind) {
        this.kind = kind;
        this.entity = new Entity(kind.entityType);
        this.entity.setNoGravity(true);
    }

    public Kind kind() {
        return kind;
    }

    public Entity entity() {
        return entity;
    }

    public boolean isDestroyed() {
        return destroyed;
    }

    /** Spawn into an instance at a position (tick-dispatched). */
    public void spawn(Instance instance, Pos position) {
        TickDispatch.call(() -> {
            entity.setInstance(instance, position);
            return null;
        });
        DisplayRegistry.track(this);
    }

    private void checkAlive() {
        if (destroyed) {
            throw new ScriptError("this display was destroyed");
        }
    }

    // ------------------------------------------------------------------
    // shared display meta
    // ------------------------------------------------------------------

    private AbstractDisplayMeta meta() {
        return (AbstractDisplayMeta) entity.getEntityMeta();
    }

    public Vec getScale() {
        return meta().getScale();
    }

    public void setScale(Vec scale) {
        checkAlive();
        entity.editEntityMeta(AbstractDisplayMeta.class, meta -> meta.setScale(scale));
    }

    public Vec getTranslation() {
        var translation = meta().getTranslation();
        return new Vec(translation.x(), translation.y(), translation.z());
    }

    public void setTranslation(Vec translation) {
        checkAlive();
        entity.editEntityMeta(AbstractDisplayMeta.class, meta -> meta.setTranslation(translation));
    }

    public Vec getRotationEuler() {
        return new Vec(eulerX, eulerY, eulerZ);
    }

    /**
     * Euler degrees (pitch x, yaw y, roll z) converted to a quaternion on
     * the meta's left rotation. ZYX (roll-yaw-pitch) application order.
     */
    public void setRotationEuler(double degX, double degY, double degZ) {
        checkAlive();
        this.eulerX = degX;
        this.eulerY = degY;
        this.eulerZ = degZ;
        float[] quaternion = eulerToQuaternion(degX, degY, degZ);
        entity.editEntityMeta(AbstractDisplayMeta.class, meta -> meta.setLeftRotation(quaternion));
    }

    /** Returns {x, y, z, w}. */
    static float[] eulerToQuaternion(double degX, double degY, double degZ) {
        double x = Math.toRadians(degX) / 2.0;
        double y = Math.toRadians(degY) / 2.0;
        double z = Math.toRadians(degZ) / 2.0;
        double cx = Math.cos(x), sx = Math.sin(x);
        double cy = Math.cos(y), sy = Math.sin(y);
        double cz = Math.cos(z), sz = Math.sin(z);
        return new float[]{
                (float) (sx * cy * cz - cx * sy * sz),
                (float) (cx * sy * cz + sx * cy * sz),
                (float) (cx * cy * sz - sx * sy * cz),
                (float) (cx * cy * cz + sx * sy * sz)};
    }

    public String getBillboard() {
        return meta().getBillboardRenderConstraints().name().toLowerCase();
    }

    public void setBillboard(String mode) {
        checkAlive();
        AbstractDisplayMeta.BillboardConstraints constraints;
        try {
            constraints = AbstractDisplayMeta.BillboardConstraints.valueOf(mode.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ScriptError("unknown billboard mode '" + mode
                    + "' (valid: fixed, vertical, horizontal, center)");
        }
        entity.editEntityMeta(AbstractDisplayMeta.class,
                meta -> meta.setBillboardRenderConstraints(constraints));
    }

    public int getGlowColor() {
        return meta().getGlowColorOverride();
    }

    public void setGlowColor(int argb) {
        checkAlive();
        entity.editEntityMeta(AbstractDisplayMeta.class, meta -> {
            meta.setHasGlowingEffect(true);
            meta.setGlowColorOverride(argb);
        });
    }

    public float getViewRange() {
        return meta().getViewRange();
    }

    public void setViewRange(float range) {
        checkAlive();
        entity.editEntityMeta(AbstractDisplayMeta.class, meta -> meta.setViewRange(range));
    }

    public float getShadowRadius() {
        return meta().getShadowRadius();
    }

    public void setShadowRadius(float radius) {
        checkAlive();
        entity.editEntityMeta(AbstractDisplayMeta.class, meta -> meta.setShadowRadius(radius));
    }

    // ------------------------------------------------------------------
    // text display
    // ------------------------------------------------------------------

    private TextDisplayMeta textMeta() {
        if (!(entity.getEntityMeta() instanceof TextDisplayMeta meta)) {
            throw new ScriptError("this property only exists on text displays");
        }
        return meta;
    }

    public String getText() {
        return TextFormat.plain(textMeta().getText());
    }

    public void setText(String text) {
        checkAlive();
        textMeta();
        Component component = TextFormat.component(text);
        entity.editEntityMeta(TextDisplayMeta.class, meta -> meta.setText(component));
    }

    public int getLineWidth() {
        return textMeta().getLineWidth();
    }

    public void setLineWidth(int width) {
        checkAlive();
        textMeta();
        entity.editEntityMeta(TextDisplayMeta.class, meta -> meta.setLineWidth(width));
    }

    public int getBackground() {
        return textMeta().getBackgroundColor();
    }

    public void setBackground(int argb) {
        checkAlive();
        textMeta();
        entity.editEntityMeta(TextDisplayMeta.class, meta -> {
            meta.setUseDefaultBackground(false);
            meta.setBackgroundColor(argb);
        });
    }

    public boolean isSeeThrough() {
        return textMeta().isSeeThrough();
    }

    public void setSeeThrough(boolean seeThrough) {
        checkAlive();
        textMeta();
        entity.editEntityMeta(TextDisplayMeta.class, meta -> meta.setSeeThrough(seeThrough));
    }

    public String getAlignment() {
        return textMeta().getAlignment().name().toLowerCase();
    }

    public void setAlignment(String alignment) {
        checkAlive();
        textMeta();
        TextDisplayMeta.Alignment value;
        try {
            value = TextDisplayMeta.Alignment.valueOf(alignment.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ScriptError("unknown alignment '" + alignment
                    + "' (valid: center, left, right)");
        }
        entity.editEntityMeta(TextDisplayMeta.class, meta -> meta.setAlignment(value));
    }

    // ------------------------------------------------------------------
    // item / block display
    // ------------------------------------------------------------------

    public ItemStack getItem() {
        if (!(entity.getEntityMeta() instanceof ItemDisplayMeta meta)) {
            throw new ScriptError("the 'item' property only exists on item displays");
        }
        return meta.getItemStack();
    }

    public void setItem(ItemStack stack) {
        checkAlive();
        getItem();
        entity.editEntityMeta(ItemDisplayMeta.class, meta -> meta.setItemStack(stack));
    }

    public String getBlock() {
        if (!(entity.getEntityMeta() instanceof BlockDisplayMeta meta)) {
            throw new ScriptError("the 'block' property only exists on block displays");
        }
        return meta.getBlockStateId().name();
    }

    public void setBlock(String blockName) {
        checkAlive();
        getBlock();
        String key = blockName.contains(":") ? blockName.toLowerCase()
                : "minecraft:" + blockName.toLowerCase();
        Block block = Block.fromKey(key);
        if (block == null) {
            throw new ScriptError("unknown block '" + blockName + "'");
        }
        entity.editEntityMeta(BlockDisplayMeta.class, meta -> meta.setBlockState(block));
    }

    // ------------------------------------------------------------------
    // per-viewer visibility, mounting, movement, teardown
    // ------------------------------------------------------------------

    /**
     * First show/hide flips into manual viewer mode: auto-viewing stops and
     * the manual set drives who receives the entity.
     */
    private void enterManualMode() {
        if (!manualVisibility) {
            manualVisibility = true;
            manualViewers.addAll(entity.getViewers());
            entity.setAutoViewable(false);
        }
    }

    public void show(Player viewer) {
        checkAlive();
        enterManualMode();
        manualViewers.add(viewer);
        TickDispatch.call(() -> {
            if (!entity.getViewers().contains(viewer)) {
                entity.addViewer(viewer);
            }
            return null;
        });
    }

    public void hide(Player viewer) {
        checkAlive();
        enterManualMode();
        manualViewers.remove(viewer);
        TickDispatch.call(() -> {
            entity.removeViewer(viewer);
            return null;
        });
    }

    /** Show to everyone again: back to auto-viewable. */
    public void showAll() {
        checkAlive();
        manualVisibility = false;
        manualViewers.clear();
        TickDispatch.call(() -> {
            entity.setAutoViewable(true);
            return null;
        });
    }

    public void hideAll() {
        checkAlive();
        enterManualMode();
        manualViewers.clear();
        TickDispatch.call(() -> {
            for (Player viewer : Set.copyOf(entity.getViewers())) {
                entity.removeViewer(viewer);
            }
            return null;
        });
    }

    /** Mount this display on an anchor entity (display groups). */
    public void mountOn(Entity anchor) {
        checkAlive();
        TickDispatch.call(() -> {
            // self-mounts and passenger cycles overflow the stack inside
            // Minestom's addPassenger recursion — reject them first
            net.swofty.nativebridge.execution.commands.entities.EntityValues
                    .checkMountCycle(entity, anchor, "mount display");
            anchor.addPassenger(entity);
            return null;
        });
    }

    public void unmount() {
        checkAlive();
        TickDispatch.call(() -> {
            Entity vehicle = entity.getVehicle();
            if (vehicle != null) {
                vehicle.removePassenger(entity);
            }
            return null;
        });
    }

    public void teleport(Pos position) {
        checkAlive();
        TickDispatch.call(() -> entity.teleport(position));
    }

    public void destroy() {
        if (destroyed) {
            return;
        }
        destroyed = true;
        DisplayRegistry.untrack(this);
        TickDispatch.call(() -> {
            entity.remove();
            return null;
        });
    }

    @Override
    public String toString() {
        return "display:" + kind.name().toLowerCase() + "#" + entity.getEntityId();
    }
}
