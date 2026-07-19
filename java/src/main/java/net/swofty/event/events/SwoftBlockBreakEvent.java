package net.swofty.event.events;

import net.minestom.server.command.CommandSender;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.event.player.PlayerBlockBreakEvent;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.nativebridge.representation.Event;

/**
 * event BlockBreak { player, block, location, cancelled } wrapper over
 * PlayerBlockBreakEvent (design 6D).
 */
public class SwoftBlockBreakEvent extends AbstractSwoftEvent<PlayerBlockBreakEvent> {
    public SwoftBlockBreakEvent(PlayerBlockBreakEvent minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
    }

    public Player getPlayer() {
        return minestomEvent.getPlayer();
    }

    /** Block key, e.g. "minecraft:stone". */
    public String getBlock() {
        return minestomEvent.getBlock().name();
    }

    public Pos getLocation() {
        var position = minestomEvent.getBlockPosition();
        return new Pos(position.x(), position.y(), position.z());
    }

    /** Clicked block face, lowercase (e.g. "top"). */
    public String getBlockFace() {
        return minestomEvent.getBlockFace().name().toLowerCase(java.util.Locale.ROOT);
    }

    /** Block the break resolves to (usually air), as a key like "minecraft:air". */
    public String getResultBlock() {
        return minestomEvent.getResultBlock().name();
    }

    public void setResultBlock(String key) {
        String name = key.contains(":") ? key.toLowerCase(java.util.Locale.ROOT)
                : "minecraft:" + key.toLowerCase(java.util.Locale.ROOT);
        net.minestom.server.instance.block.Block block =
                net.minestom.server.instance.block.Block.fromKey(name);
        if (block == null) {
            throw new net.swofty.ScriptError("unknown block '" + key + "' for result_block");
        }
        minestomEvent.setResultBlock(block);
    }

    @Override
    public CommandSender getSender() {
        return minestomEvent.getPlayer();
    }
}
