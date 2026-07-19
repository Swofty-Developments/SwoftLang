package net.swofty.compiler;

import java.util.List;

import net.swofty.model.ApiHandlerModel;
import net.swofty.model.BossbarModel;
import net.swofty.model.EveryDeclModel;
import net.swofty.model.FishingLootModel;
import net.swofty.model.GuiModel;
import net.swofty.model.HologramModel;
import net.swofty.model.ItemDefModel;
import net.swofty.model.MobDefModel;
import net.swofty.model.NpcModel;
import net.swofty.model.PacketHandlerModel;
import net.swofty.model.PersistentDeclModel;
import net.swofty.model.ScoreboardModel;
import net.swofty.model.ServerConfigModel;
import net.swofty.model.StorageConfigModel;
import net.swofty.model.TablistModel;
import net.swofty.nativebridge.representation.Command;
import net.swofty.nativebridge.representation.Event;

public record ParsedScript(
        List<Command> commands,
        List<Event> events,
        List<SwoftFunction> functions,
        List<GuiModel> guis,
        List<ScoreboardModel> scoreboards,
        List<TablistModel> tablists,
        List<BossbarModel> bossbars,
        ServerConfigModel server,
        StorageConfigModel storage,
        List<PersistentDeclModel> persistents,
        List<ItemDefModel> items,
        List<MobDefModel> mobs,
        List<PacketHandlerModel> packetHandlers,
        List<ApiHandlerModel> apis,
        List<EveryDeclModel> everyDecls,
        List<FishingLootModel> fishingLoot,
        List<HologramModel> holograms,
        List<NpcModel> npcs) {

    /**
     * Pre-npc/hologram shape, kept for existing call sites and tests: no
     * first-class holograms/npcs (GROUP C/D).
     */
    public ParsedScript(List<Command> commands, List<Event> events,
            List<SwoftFunction> functions, List<GuiModel> guis,
            List<ScoreboardModel> scoreboards, List<TablistModel> tablists,
            List<BossbarModel> bossbars, ServerConfigModel server,
            StorageConfigModel storage, List<PersistentDeclModel> persistents,
            List<ItemDefModel> items, List<MobDefModel> mobs,
            List<PacketHandlerModel> packetHandlers, List<ApiHandlerModel> apis,
            List<EveryDeclModel> everyDecls, List<FishingLootModel> fishingLoot) {
        this(commands, events, functions, guis, scoreboards, tablists, bossbars,
                server, storage, persistents, items, mobs, packetHandlers,
                apis, everyDecls, fishingLoot, List.of(), List.of());
    }

    /** Pre-phase-8 shape, kept for existing call sites and tests. */
    public ParsedScript(List<Command> commands, List<Event> events,
            List<SwoftFunction> functions, List<GuiModel> guis,
            List<ScoreboardModel> scoreboards, List<TablistModel> tablists,
            List<BossbarModel> bossbars, ServerConfigModel server,
            StorageConfigModel storage, List<PersistentDeclModel> persistents,
            List<ItemDefModel> items, List<MobDefModel> mobs,
            List<PacketHandlerModel> packetHandlers, List<ApiHandlerModel> apis,
            List<EveryDeclModel> everyDecls) {
        this(commands, events, functions, guis, scoreboards, tablists, bossbars,
                server, storage, persistents, items, mobs, packetHandlers,
                apis, everyDecls, List.of());
    }

    /** Pre-phase-6 shape, kept for existing call sites and tests. */
    public ParsedScript(List<Command> commands, List<Event> events,
            List<SwoftFunction> functions, List<GuiModel> guis,
            List<ScoreboardModel> scoreboards, List<TablistModel> tablists,
            List<BossbarModel> bossbars, ServerConfigModel server,
            StorageConfigModel storage, List<PersistentDeclModel> persistents,
            List<ItemDefModel> items, List<MobDefModel> mobs,
            List<PacketHandlerModel> packetHandlers) {
        this(commands, events, functions, guis, scoreboards, tablists, bossbars,
                server, storage, persistents, items, mobs, packetHandlers,
                List.of(), List.of(), List.of());
    }
}
