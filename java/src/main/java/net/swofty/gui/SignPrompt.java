package net.swofty.gui;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;

import net.kyori.adventure.nbt.ByteBinaryTag;
import net.kyori.adventure.nbt.CompoundBinaryTag;
import net.kyori.adventure.nbt.ListBinaryTag;
import net.kyori.adventure.nbt.StringBinaryTag;
import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.instance.block.Block;
import net.minestom.server.network.packet.client.play.ClientUpdateSignPacket;
import net.minestom.server.network.packet.server.play.BlockChangePacket;
import net.minestom.server.network.packet.server.play.BlockEntityDataPacket;
import net.minestom.server.network.packet.server.play.OpenSignEditorPacket;
import net.minestom.server.timer.TaskSchedule;

/**
 * prompt_input mechanism: a fake oak sign 6 blocks above the player, opened
 * with OpenSignEditorPacket after 2 ticks; the ClientUpdateSignPacket
 * listener completes the future with the first line and restores the real
 * block.
 */
final class SignPrompt {
    private record Pending(CompletableFuture<String> future, Pos pos, Block realBlock) {
    }

    private static final Map<UUID, Pending> PENDING = new ConcurrentHashMap<>();

    private SignPrompt() {
    }

    static CompletableFuture<String> open(Player player, String placeholder) {
        Pos pos = player.getPosition().add(0, 6, 0);
        CompoundBinaryTag data = CompoundBinaryTag.builder()
                .put("is_waxed", ByteBinaryTag.byteBinaryTag((byte) 0))
                .put("back_text", sideText("", ""))
                .put("front_text", sideText(placeholder, ""))
                .build();

        player.sendPackets(
                new BlockChangePacket(pos, Block.OAK_SIGN),
                new BlockEntityDataPacket(pos, Block.OAK_SIGN.registry().blockEntityId(), data));
        MinecraftServer.getSchedulerManager().scheduleTask(
                () -> player.sendPacket(new OpenSignEditorPacket(pos, true)),
                TaskSchedule.tick(2), TaskSchedule.stop());

        CompletableFuture<String> future = new CompletableFuture<>();
        Block realBlock = player.getInstance() != null ? player.getInstance().getBlock(pos) : Block.AIR;
        Pending previous = PENDING.put(player.getUuid(), new Pending(future, pos, realBlock));
        if (previous != null) {
            previous.future().complete("");
        }
        return future;
    }

    private static CompoundBinaryTag sideText(String line2, String line3) {
        return CompoundBinaryTag.builder()
                .put("has_glowing_text", ByteBinaryTag.byteBinaryTag((byte) 0))
                .put("color", StringBinaryTag.stringBinaryTag("black"))
                .put("messages", ListBinaryTag.from(List.of(
                        StringBinaryTag.stringBinaryTag(""),
                        StringBinaryTag.stringBinaryTag("^^^^^^^^"),
                        StringBinaryTag.stringBinaryTag(line2),
                        StringBinaryTag.stringBinaryTag(line3))))
                .build();
    }

    /**
     * Called from the PlayerPacketEvent listener registered by GuiRuntime
     */
    static void onSignUpdate(Player player, ClientUpdateSignPacket packet) {
        Pending pending = PENDING.remove(player.getUuid());
        if (pending == null) {
            return;
        }
        player.sendPacket(new BlockChangePacket(pending.pos(), pending.realBlock()));
        pending.future().complete(packet.lines().isEmpty() ? "" : packet.lines().get(0));
    }

    static void cancel(Player player) {
        Pending pending = PENDING.remove(player.getUuid());
        if (pending != null) {
            pending.future().complete("");
        }
    }
}
