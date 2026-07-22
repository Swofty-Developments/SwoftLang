package net.swofty.compiler;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import net.swofty.nametags.NametagRuntime;
import net.swofty.model.BossbarModel;
import net.swofty.model.HologramModel;
import net.swofty.model.NpcModel;
import net.swofty.model.NpcModel.NpcSkinModel;
import net.swofty.model.ItemClickHandlerModel;
import net.swofty.model.ItemDefModel;
import net.swofty.model.MobDefModel;
import net.swofty.model.MobDropModel;
import net.swofty.model.PacketHandlerModel;
import net.swofty.model.GuiClickHandlerModel;
import net.swofty.model.GuiEditableModel;
import net.swofty.model.GuiModel;
import net.swofty.model.GuiPaginateModel;
import net.swofty.model.GuiSlotModel;
import net.swofty.model.ItemSpecModel;
import net.swofty.model.PersistentDeclModel;
import net.swofty.model.StorageBackendModel;
import net.swofty.model.StorageConfigModel;
import net.swofty.model.ScoreboardModel;
import net.swofty.model.ServerConfigModel;
import net.swofty.model.SkinSpecModel;
import net.swofty.model.TablistColumnModel;
import net.swofty.model.TablistModel;
import net.swofty.model.UpdateCadence;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.BlockStatement;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.nativebridge.execution.commands.AsyncBlockStatement;
import net.swofty.nativebridge.execution.commands.CallOriginalStatement;
import net.swofty.nativebridge.execution.commands.CancelEventStatement;
import net.swofty.nativebridge.execution.commands.ForEachStatement;
import net.swofty.nativebridge.execution.commands.FunctionCallStatement;
import net.swofty.nativebridge.execution.commands.HaltCommand;
import net.swofty.nativebridge.execution.commands.IfStatement;
import net.swofty.nativebridge.execution.commands.IndexAssignStatement;
import net.swofty.nativebridge.execution.commands.LoopStatement;
import net.swofty.nativebridge.execution.commands.PersistSetStatement;
import net.swofty.nativebridge.execution.commands.ReturnStatement;
import net.swofty.nativebridge.execution.commands.SendCommand;
import net.swofty.nativebridge.execution.commands.SetPropertyStatement;
import net.swofty.nativebridge.execution.commands.SpawnStatement;
import net.swofty.nativebridge.execution.commands.TeleportCommand;
import net.swofty.nativebridge.execution.commands.VariableAssignment;
import net.swofty.nativebridge.execution.commands.WaitStatement;
import net.swofty.nativebridge.execution.commands.WhileStatement;
import net.swofty.nativebridge.execution.commands.items.GiveItemStatement;
import net.swofty.nativebridge.execution.commands.mobs.DespawnMobStatement;
import net.swofty.nativebridge.execution.commands.mobs.SpawnMobStatement;
import net.swofty.nativebridge.execution.commands.nametag.ResetNametagStatement;
import net.swofty.nativebridge.execution.commands.nametag.SetNametagStatement;
import net.swofty.nativebridge.execution.commands.packets.CancelPacketStatement;
import net.swofty.nativebridge.execution.commands.packets.SendPacketStatement;
import net.swofty.nativebridge.execution.commands.gui.CloseGuiStatement;
import net.swofty.nativebridge.execution.commands.gui.GuiBackStatement;
import net.swofty.nativebridge.execution.commands.gui.OpenGuiStatement;
import net.swofty.nativebridge.execution.commands.ui.ActionbarStatement;
import net.swofty.nativebridge.execution.commands.ui.BelownameStatement;
import net.swofty.nativebridge.execution.commands.ui.ClearTitleStatement;
import net.swofty.nativebridge.execution.commands.ui.EntryStatement;
import net.swofty.nativebridge.execution.commands.ui.HideBossbarStatement;
import net.swofty.nativebridge.execution.commands.ui.HideScoreboardStatement;
import net.swofty.nativebridge.execution.commands.ui.HideTablistStatement;
import net.swofty.nativebridge.execution.commands.ui.LineStatement;
import net.swofty.nativebridge.execution.commands.ui.SetBossbarPartStatement;
import net.swofty.nativebridge.execution.commands.ui.SetTablistPartStatement;
import net.swofty.nativebridge.execution.commands.ui.ShowBossbarStatement;
import net.swofty.nativebridge.execution.commands.holograms.ShowHologramStatement;
import net.swofty.nativebridge.execution.commands.holograms.HideHologramStatement;
import net.swofty.nativebridge.execution.commands.holograms.MoveHologramStatement;
import net.swofty.nativebridge.execution.commands.holograms.SetHologramLineStatement;
import net.swofty.nativebridge.execution.commands.holograms.RemoveHologramStatement;
import net.swofty.nativebridge.execution.commands.npcs.SetNpcSkinStatement;
import net.swofty.nativebridge.execution.commands.npcs.SetNpcNameStatement;
import net.swofty.nativebridge.execution.commands.npcs.SetNpcLocationStatement;
import net.swofty.nativebridge.execution.commands.npcs.RemoveNpcStatement;
import net.swofty.nativebridge.execution.commands.ui.ShowScoreboardStatement;
import net.swofty.nativebridge.execution.commands.ui.ShowTablistStatement;
import net.swofty.nativebridge.execution.commands.ui.TitleStatement;
import net.swofty.nativebridge.execution.commands.ui.UpdateScoreboardStatement;
import net.swofty.nativebridge.execution.expressions.AllPlayersExpression;
import net.swofty.nativebridge.execution.expressions.BinaryExpression;
import net.swofty.nativebridge.execution.expressions.BooleanLiteral;
import net.swofty.nativebridge.execution.expressions.FunctionCallExpression;
import net.swofty.nativebridge.execution.expressions.IndexExpression;
import net.swofty.nativebridge.execution.expressions.ItemSpecExpression;
import net.swofty.nativebridge.execution.expressions.LambdaExpression;
import net.swofty.nativebridge.execution.expressions.ListLiteral;
import net.swofty.nativebridge.execution.expressions.NoneLiteral;
import net.swofty.nativebridge.execution.expressions.ObjectLiteralExpression;
import net.swofty.nativebridge.execution.expressions.NumberLiteral;
import net.swofty.nativebridge.execution.expressions.PersistGetExpression;
import net.swofty.nativebridge.execution.expressions.PropertyAccessExpression;
import net.swofty.nativebridge.execution.expressions.StringLiteral;
import net.swofty.nativebridge.execution.expressions.TypeLiteral;
import net.swofty.nativebridge.execution.expressions.UnaryExpression;
import net.swofty.nativebridge.execution.expressions.VariableReference;
import net.swofty.nativebridge.representation.BaseType;
import net.swofty.nativebridge.representation.Command;
import net.swofty.nativebridge.representation.DataType;
import net.swofty.nativebridge.representation.Event;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.nativebridge.representation.Variable;

/**
 * Deserializes the swoftc JSON AST (schema versions 1 and 2) into the
 * execution object graph plus the phase-2 declaration models. All nodes
 * carry the source line/col emitted by swoftc.
 */
public class SwoftJsonLoader {

    /**
     * Module owning the declarations currently being built (bundle loads
     * only); every ExecuteBlock created while set is tagged with it so the
     * runtime can enter the module's scope. Loading is single-threaded.
     */
    private static String currentModule;

    /**
     * Workspace-relative source file of the declarations currently being
     * built; stamped onto every statement node so the debug tracer can cite
     * its file. Bundle loads override this per module. Loading is
     * single-threaded.
     */
    private static String currentFile;

    /**
     * Load a JSON AST document into a ParsedScript. Accepts both the flat
     * single-script shape and the multi-module bundle shape
     * {@code {"format":..., "version":2, "modules":[...]}} (design 6A).
     * @param json The JSON emitted by swoftc (or a .sw.json sidecar)
     * @return The parsed script (bundle: all modules merged)
     */
    public static ParsedScript load(String json) {
        return load(json, null);
    }

    /**
     * Load a JSON AST, stamping every statement node with {@code sourceFile}
     * (a workspace-relative path such as "scripts/chat.sw") for the debug
     * tracer. The flat-script overload passes null.
     */
    public static ParsedScript load(String json, String sourceFile) {
        String previousFile = currentFile;
        currentFile = sourceFile;
        try {
            return loadInternal(json);
        } finally {
            currentFile = previousFile;
        }
    }

    private static ParsedScript loadInternal(String json) {
        JsonObject root = JsonParser.parseString(json).getAsJsonObject();
        if (root.has("error") && !root.get("error").isJsonNull()) {
            JsonObject error = root.getAsJsonObject("error");
            throw new IllegalArgumentException("swoftc reported a parse error: "
                    + optString(error, "message"));
        }

        int version = root.has("version") ? root.get("version").getAsInt() : 1;
        if (version < 1 || version > 2) {
            throw new IllegalArgumentException("Unsupported swoftlang-ast version: " + version);
        }

        if (has(root, "modules")) {
            return loadBundle(root);
        }
        return readScript(root);
    }

    /** One parsed-but-not-yet-committed bundle module. */
    private record StagedModule(String name, String path, boolean entry,
            ParsedScript part, List<ModuleRegistry.VarDecl> varDecls) {
    }

    /**
     * Bundle load: each module registers once (a module already loaded by
     * an earlier entry script is skipped entirely), exported symbols merge
     * into the global registries with per-symbol provenance, and module
     * variables initialize in bundle order — the compiler emits modules in
     * dependency order, so a module's imports are always initialized first.
     * The load is atomic: every module parses and every symbol claim is
     * validated against the registries BEFORE anything commits, so a
     * cross-unit collision throws without leaving a half-registered module
     * in loadedPaths (which later importers would silently skip, binding
     * the wrong module's exports). The returned ParsedScript is the merged
     * view of the newly loaded modules; its functions() list contains
     * exactly the globally visible set (exported functions), while private
     * functions — entry-module ones included — live in the ModuleRegistry
     * alone and resolve module-locally through their blocks' module tag.
     */
    private static ParsedScript loadBundle(JsonObject root) {
        // ---- stage: parse every not-yet-loaded module, no registry writes
        List<StagedModule> staged = new ArrayList<>();
        for (JsonElement element : root.getAsJsonArray("modules")) {
            JsonObject moduleObj = element.getAsJsonObject();
            String name = moduleObj.get("name").getAsString();
            String path = has(moduleObj, "path") ? moduleObj.get("path").getAsString() : name;
            boolean entry = optBoolean(moduleObj, "entry");
            if (ModuleRegistry.isLoaded(path)) {
                continue; // already registered through another entry script
            }
            currentModule = name;
            String previousFile = currentFile;
            // each bundle module's statements cite the module's own source
            currentFile = has(moduleObj, "path")
                    ? moduleObj.get("path").getAsString() : previousFile;
            try {
                ParsedScript part = readScript(moduleObj);
                List<ModuleRegistry.VarDecl> varDecls = new ArrayList<>();
                for (JsonElement varElement : optArray(moduleObj, "module_vars")) {
                    JsonObject varObj = varElement.getAsJsonObject();
                    varDecls.add(new ModuleRegistry.VarDecl(
                            varObj.get("name").getAsString(),
                            buildExpression(varObj.getAsJsonObject("value"))));
                }
                staged.add(new StagedModule(name, path, entry, part, varDecls));
            } finally {
                currentModule = null;
                currentFile = previousFile;
            }
        }

        // ---- validate: module names + every symbol claim, before committing
        Map<String, String> stagedSymbols = new LinkedHashMap<>();
        for (StagedModule module : staged) {
            ModuleRegistry.checkRegisterable(module.name(), module.path());
            for (SwoftFunction function : module.part().functions()) {
                if (function.exported()) {
                    checkStagedSymbol(stagedSymbols, "exported function", function.name(),
                            module);
                    FunctionRegistry.checkRegisterable(function);
                }
            }
            for (ItemDefModel item : module.part().items()) {
                checkStagedSymbol(stagedSymbols, "item", item.id(), module);
            }
            for (MobDefModel mob : module.part().mobs()) {
                checkStagedSymbol(stagedSymbols, "mob", mob.id(), module);
            }
            for (GuiModel gui : module.part().guis()) {
                checkStagedSymbol(stagedSymbols, "gui", gui.name(), module);
            }
            for (ScoreboardModel scoreboard : module.part().scoreboards()) {
                checkStagedSymbol(stagedSymbols, "scoreboard", scoreboard.name(), module);
            }
            for (TablistModel tablist : module.part().tablists()) {
                checkStagedSymbol(stagedSymbols, "tablist", tablist.name(), module);
            }
            for (BossbarModel bossbar : module.part().bossbars()) {
                checkStagedSymbol(stagedSymbols, "bossbar", bossbar.name(), module);
            }
            for (PersistentDeclModel persistent : module.part().persistents()) {
                checkStagedSymbol(stagedSymbols, "persistent", persistent.name(), module);
            }
        }

        // ---- commit: registries + merged view; nothing below can collide
        List<Command> commands = new ArrayList<>();
        List<Event> events = new ArrayList<>();
        List<SwoftFunction> functions = new ArrayList<>();
        List<GuiModel> guis = new ArrayList<>();
        List<ScoreboardModel> scoreboards = new ArrayList<>();
        List<TablistModel> tablists = new ArrayList<>();
        List<BossbarModel> bossbars = new ArrayList<>();
        ServerConfigModel server = null;
        StorageConfigModel storage = null;
        List<PersistentDeclModel> persistents = new ArrayList<>();
        List<ItemDefModel> items = new ArrayList<>();
        List<MobDefModel> mobs = new ArrayList<>();
        List<PacketHandlerModel> packetHandlers = new ArrayList<>();
        List<net.swofty.model.ApiHandlerModel> apis = new ArrayList<>();
        List<net.swofty.model.EveryDeclModel> everyDecls = new ArrayList<>();
        List<net.swofty.model.FishingLootModel> fishingLoot = new ArrayList<>();
        List<HologramModel> holograms = new ArrayList<>();
        List<NpcModel> npcs = new ArrayList<>();
        List<net.swofty.model.BlockHandlerModel> blockHandlers = new ArrayList<>();
        List<net.swofty.model.PlacementRuleModel> placementRules = new ArrayList<>();
        List<net.swofty.model.StructDefModel> structs = new ArrayList<>();

        List<ModuleRegistry.Module> loaded = new ArrayList<>();
        for (StagedModule stagedModule : staged) {
            ParsedScript part = stagedModule.part();
            ModuleRegistry.Module module = ModuleRegistry.register(
                    stagedModule.name(), stagedModule.path(), stagedModule.entry());
            loaded.add(module);

            for (SwoftFunction function : part.functions()) {
                module.addFunction(function);
                if (function.exported()) {
                    ModuleRegistry.claimSymbol("exported function", function.name(), module);
                    // entry-module PRIVATE functions stay module-local: their
                    // call sites run with the context module set (bundle
                    // blocks carry their module tag), so lookupFunction finds
                    // them via ModuleRegistry.lookup — registering them
                    // globally would collide across independent entry units
                    FunctionRegistry.register(function);
                    functions.add(function);
                }
            }
            for (ItemDefModel item : part.items()) {
                ModuleRegistry.claimSymbol("item", item.id(), module);
            }
            for (MobDefModel mob : part.mobs()) {
                ModuleRegistry.claimSymbol("mob", mob.id(), module);
            }
            for (GuiModel gui : part.guis()) {
                ModuleRegistry.claimSymbol("gui", gui.name(), module);
            }
            for (ScoreboardModel scoreboard : part.scoreboards()) {
                ModuleRegistry.claimSymbol("scoreboard", scoreboard.name(), module);
            }
            for (TablistModel tablist : part.tablists()) {
                ModuleRegistry.claimSymbol("tablist", tablist.name(), module);
            }
            for (BossbarModel bossbar : part.bossbars()) {
                ModuleRegistry.claimSymbol("bossbar", bossbar.name(), module);
            }
            for (HologramModel hologram : part.holograms()) {
                ModuleRegistry.claimSymbol("hologram", hologram.name(), module);
            }
            for (NpcModel npc : part.npcs()) {
                ModuleRegistry.claimSymbol("npc", npc.name(), module);
            }
            for (PersistentDeclModel persistent : part.persistents()) {
                ModuleRegistry.claimSymbol("persistent", persistent.name(), module);
            }

            for (ModuleRegistry.VarDecl decl : stagedModule.varDecls()) {
                module.addVarDecl(decl);
            }

            commands.addAll(part.commands());
            events.addAll(part.events());
            guis.addAll(part.guis());
            scoreboards.addAll(part.scoreboards());
            tablists.addAll(part.tablists());
            bossbars.addAll(part.bossbars());
            if (server == null) {
                server = part.server();
            }
            if (storage == null) {
                storage = part.storage();
            }
            persistents.addAll(part.persistents());
            items.addAll(part.items());
            mobs.addAll(part.mobs());
            packetHandlers.addAll(part.packetHandlers());
            apis.addAll(part.apis());
            everyDecls.addAll(part.everyDecls());
            fishingLoot.addAll(part.fishingLoot());
            holograms.addAll(part.holograms());
            npcs.addAll(part.npcs());
            blockHandlers.addAll(part.blockHandlers());
            placementRules.addAll(part.placementRules());
            structs.addAll(part.structs());
        }

        // module vars initialize at load, in dependency order
        for (ModuleRegistry.Module module : loaded) {
            ModuleRegistry.initialize(module);
        }

        return new ParsedScript(commands, events, functions, guis, scoreboards,
                tablists, bossbars, server, storage, persistents,
                items, mobs, packetHandlers, apis, everyDecls, fishingLoot,
                holograms, npcs, blockHandlers, placementRules, structs);
    }

    /**
     * Validation-phase symbol check: against both the committed registry
     * state and the other modules staged in this same bundle
     */
    private static void checkStagedSymbol(Map<String, String> stagedSymbols, String kind,
            String id, StagedModule module) {
        ModuleRegistry.checkSymbol(kind, id, module.name(), module.path());
        String where = "module '" + module.name() + "' (" + module.path() + ")";
        String previous = stagedSymbols.putIfAbsent(kind + ":" + id, where);
        if (previous != null && !previous.equals(where)) {
            throw new IllegalStateException("duplicate " + kind + " '" + id
                    + "': declared in both " + previous + " and " + where);
        }
    }

    /** Read one script-shaped object (a flat document or a bundle module). */
    private static ParsedScript readScript(JsonObject root) {
        List<Command> commands = new ArrayList<>();
        for (JsonElement element : optArray(root, "commands")) {
            buildCommands(element.getAsJsonObject(), commands);
        }

        List<Event> events = new ArrayList<>();
        for (JsonElement element : optArray(root, "events")) {
            events.add(buildEvent(element.getAsJsonObject()));
        }

        List<SwoftFunction> functions = new ArrayList<>();
        for (JsonElement element : optArray(root, "functions")) {
            functions.add(buildFunction(element.getAsJsonObject()));
        }

        List<GuiModel> guis = new ArrayList<>();
        for (JsonElement element : optArray(root, "guis")) {
            guis.add(buildGui(element.getAsJsonObject()));
        }

        List<ScoreboardModel> scoreboards = new ArrayList<>();
        for (JsonElement element : optArray(root, "scoreboards")) {
            scoreboards.add(buildScoreboard(element.getAsJsonObject()));
        }

        List<TablistModel> tablists = new ArrayList<>();
        for (JsonElement element : optArray(root, "tablists")) {
            tablists.add(buildTablist(element.getAsJsonObject()));
        }

        List<BossbarModel> bossbars = new ArrayList<>();
        for (JsonElement element : optArray(root, "bossbars")) {
            bossbars.add(buildBossbar(element.getAsJsonObject()));
        }

        ServerConfigModel server = has(root, "server")
                ? buildServer(root.getAsJsonObject("server")) : null;

        StorageConfigModel storage = has(root, "storage")
                ? buildStorage(root.getAsJsonObject("storage")) : null;

        List<PersistentDeclModel> persistents = new ArrayList<>();
        for (JsonElement element : optArray(root, "persistents")) {
            persistents.add(buildPersistent(element.getAsJsonObject()));
        }

        List<ItemDefModel> items = new ArrayList<>();
        for (JsonElement element : optArray(root, "items")) {
            items.add(buildItem(element.getAsJsonObject()));
        }

        List<MobDefModel> mobs = new ArrayList<>();
        for (JsonElement element : optArray(root, "mobs")) {
            mobs.add(buildMob(element.getAsJsonObject()));
        }

        List<PacketHandlerModel> packetHandlers = new ArrayList<>();
        JsonArray packetArray = has(root, "packet_listeners")
                ? root.getAsJsonArray("packet_listeners")
                : has(root, "packet_handlers")
                        ? root.getAsJsonArray("packet_handlers") : optArray(root, "on_packets");
        for (JsonElement element : packetArray) {
            JsonObject obj = element.getAsJsonObject();
            packetHandlers.add(new PacketHandlerModel(obj.get("name").getAsString(),
                    buildExecuteBlock(obj.get("execute")),
                    has(obj, "line") ? obj.get("line").getAsInt() : -1,
                    has(obj, "col") ? obj.get("col").getAsInt() : -1));
        }

        // api "/path/:param" { method, execute } declarations (design 6B)
        List<net.swofty.model.ApiHandlerModel> apis = new ArrayList<>();
        JsonArray apiArray = has(root, "apis") ? root.getAsJsonArray("apis")
                : optArray(root, "api_handlers");
        for (JsonElement element : apiArray) {
            JsonObject obj = element.getAsJsonObject();
            // execute is optional in the emitter (a bodyless api answers 204)
            ExecuteBlock execute = has(obj, "execute")
                    ? buildExecuteBlock(obj.get("execute")) : new ExecuteBlock();
            execute.setAsync(true); // api handlers are async-colored by default
            apis.add(new net.swofty.model.ApiHandlerModel(
                    obj.get("path").getAsString(),
                    has(obj, "method") ? obj.get("method").getAsString().toLowerCase() : "any",
                    execute,
                    has(obj, "line") ? obj.get("line").getAsInt() : -1,
                    has(obj, "col") ? obj.get("col").getAsInt() : -1));
        }

        // every 5 seconds { ... } declarations (design 6D); the emitter
        // writes them under "schedulers"
        List<net.swofty.model.EveryDeclModel> everyDecls = new ArrayList<>();
        JsonArray everyArray = has(root, "schedulers") ? root.getAsJsonArray("schedulers")
                : has(root, "every") ? root.getAsJsonArray("every")
                        : has(root, "every_decls") ? root.getAsJsonArray("every_decls")
                                : optArray(root, "schedules");
        for (JsonElement element : everyArray) {
            JsonObject obj = element.getAsJsonObject();
            ExecuteBlock body = buildExecuteBlock(has(obj, "body")
                    ? obj.get("body") : obj.get("execute"));
            body.setAsync(true); // every bodies are async-colored
            everyDecls.add(new net.swofty.model.EveryDeclModel(
                    durationTicks(obj, "after", "delay"),
                    durationTicks(obj, "every", "interval"),
                    optString(obj, "name"),
                    body,
                    has(obj, "line") ? obj.get("line").getAsInt() : -1,
                    has(obj, "col") ? obj.get("col").getAsInt() : -1));
        }

        // fishing_loot "name" { medium, [world], catch... } (phase 8)
        List<net.swofty.model.FishingLootModel> fishingLoot = new ArrayList<>();
        for (JsonElement element : optArray(root, "fishing_loot")) {
            fishingLoot.add(buildFishingLoot(element.getAsJsonObject()));
        }

        // first-class hologram {} / npc {} declarations (GROUP C/D)
        List<HologramModel> holograms = new ArrayList<>();
        for (JsonElement element : optArray(root, "holograms")) {
            holograms.add(buildHologram(element.getAsJsonObject()));
        }
        List<NpcModel> npcs = new ArrayList<>();
        for (JsonElement element : optArray(root, "npcs")) {
            npcs.add(buildNpc(element.getAsJsonObject()));
        }

        // W-blocks: first-class block_handler / placement_rule declarations
        List<net.swofty.model.BlockHandlerModel> blockHandlers = new ArrayList<>();
        for (JsonElement element : optArray(root, "block_handlers")) {
            blockHandlers.add(buildBlockHandler(element.getAsJsonObject()));
        }
        List<net.swofty.model.PlacementRuleModel> placementRules = new ArrayList<>();
        for (JsonElement element : optArray(root, "placement_rules")) {
            placementRules.add(buildPlacementRule(element.getAsJsonObject()));
        }

        // §1 struct declarations
        List<net.swofty.model.StructDefModel> structs = new ArrayList<>();
        for (JsonElement element : optArray(root, "structs")) {
            structs.add(buildStructDef(element.getAsJsonObject()));
        }

        return new ParsedScript(commands, events, functions, guis, scoreboards,
                tablists, bossbars, server, storage, persistents,
                items, mobs, packetHandlers, apis, everyDecls, fishingLoot,
                holograms, npcs, blockHandlers, placementRules, structs);
    }

    /**
     * A {@code block_handler "id" { on_place/on_destroy/on_interact/on_touch/
     * tick(...) { ... } }} declaration (W-blocks). Callback bodies are plain
     * statement arrays; each keeps its declared positional parameter names.
     */
    private static net.swofty.model.BlockHandlerModel buildBlockHandler(JsonObject obj) {
        return new net.swofty.model.BlockHandlerModel(
                obj.get("id").getAsString(),
                buildBlockCallbacks(obj),
                has(obj, "line") ? obj.get("line").getAsInt() : -1,
                has(obj, "col") ? obj.get("col").getAsInt() : -1);
    }

    /**
     * A {@code placement_rule for "id" { on_place/on_update(...) -> Block {...}
     * self_replaceable: bool }} declaration (W-blocks).
     */
    private static net.swofty.model.PlacementRuleModel buildPlacementRule(JsonObject obj) {
        return new net.swofty.model.PlacementRuleModel(
                obj.get("id").getAsString(),
                has(obj, "self_replaceable") && obj.get("self_replaceable").getAsBoolean(),
                buildBlockCallbacks(obj),
                has(obj, "line") ? obj.get("line").getAsInt() : -1,
                has(obj, "col") ? obj.get("col").getAsInt() : -1);
    }

    /** Shared {@code callbacks:[{name, params:[...], body:[...]}]} reader. */
    private static Map<String, net.swofty.model.BlockCallbackModel> buildBlockCallbacks(
            JsonObject obj) {
        Map<String, net.swofty.model.BlockCallbackModel> callbacks = new LinkedHashMap<>();
        for (JsonElement element : optArray(obj, "callbacks")) {
            JsonObject cb = element.getAsJsonObject();
            String name = cb.get("name").getAsString();
            List<String> params = new ArrayList<>();
            for (JsonElement param : optArray(cb, "params")) {
                params.add(param.getAsString());
            }
            callbacks.put(name, new net.swofty.model.BlockCallbackModel(
                    name, params, buildExecuteBlock(cb.get("body"))));
        }
        return callbacks;
    }

    /**
     * fishing_loot table (phase 8): name, medium (water|lava), optional
     * world, and catch entries {kind: item|mob, id, weight, message?}.
     * Weights and messages arrive either as raw JSON primitives or as
     * literal expression objects.
     */
    private static net.swofty.model.FishingLootModel buildFishingLoot(JsonObject obj) {
        List<net.swofty.model.FishingLootEntryModel> entries = new ArrayList<>();
        JsonArray catches = has(obj, "catches") ? obj.getAsJsonArray("catches")
                : optArray(obj, "entries");
        for (JsonElement element : catches) {
            JsonObject entry = element.getAsJsonObject();
            String message = has(entry, "message") ? constString(entry.get("message")) : null;
            entries.add(new net.swofty.model.FishingLootEntryModel(
                    has(entry, "kind") ? entry.get("kind").getAsString().toLowerCase()
                            : "item",
                    entry.get("id").getAsString(),
                    has(entry, "weight") ? scalarNumber(entry.get("weight")) : 1,
                    message));
        }
        return new net.swofty.model.FishingLootModel(
                firstString(obj, "name", "id"),
                has(obj, "medium") ? obj.get("medium").getAsString().toLowerCase()
                        : "water",
                firstString(obj, "world", "world_name"),
                entries,
                has(obj, "line") ? obj.get("line").getAsInt() : -1,
                has(obj, "col") ? obj.get("col").getAsInt() : -1);
    }

    /**
     * item "id" { } declaration reduced to the generic core (phase 9):
     * material XOR skull, optional rarity/glint/amount, a WYSIWYG lore
     * block, real vanilla attributes, arbitrary nested NBT tags, and
     * filtered on_click handlers. Scalar values arrive either as raw JSON
     * primitives or as literal expression objects; tag values may be
     * nested lists ({"kind":"list"}) and compounds ({"kind":"map"}).
     */
    private static ItemDefModel buildItem(JsonObject obj) {
        Map<String, Double> attributes = new LinkedHashMap<>();
        if (has(obj, "attributes")) {
            for (Map.Entry<String, JsonElement> entry
                    : obj.getAsJsonObject("attributes").entrySet()) {
                attributes.put(entry.getKey().toLowerCase(), scalarNumber(entry.getValue()));
            }
        }
        Map<String, Object> tags = new LinkedHashMap<>();
        if (has(obj, "tags")) {
            for (Map.Entry<String, JsonElement> entry : obj.getAsJsonObject("tags").entrySet()) {
                tags.put(entry.getKey(), tagValue(entry.getValue()));
            }
        }

        List<ItemClickHandlerModel> onClick = new ArrayList<>();
        if (has(obj, "on_click")) {
            for (JsonElement handler : obj.getAsJsonArray("on_click")) {
                JsonObject h = handler.getAsJsonObject();
                onClick.add(new ItemClickHandlerModel(
                        has(h, "filter") ? h.get("filter").getAsString().toLowerCase() : "any",
                        buildExecuteBlock(h.get("body"))));
            }
        }

        boolean glint = has(obj, "glint")
                && net.swofty.runtime.Values.toBoolean(scalarValue(obj.get("glint")));
        int amount = 1;
        if (has(obj, "amount")) {
            Object value = scalarValue(obj.get("amount"));
            if (value instanceof Number n) {
                amount = Math.max(1, n.intValue());
            }
        }
        return new ItemDefModel(
                obj.get("id").getAsString(),
                optString(obj, "material"),
                optString(obj, "skull"),
                constString(obj.get("name")),
                has(obj, "rarity") ? obj.get("rarity").getAsString().toLowerCase() : null,
                glint,
                amount,
                has(obj, "lore") ? buildExecuteBlock(obj.get("lore")) : null,
                attributes, tags, onClick, buildInlineHandlers(obj),
                // §2 nominal custom types: the Capitalized type name
                // (AspectOfTheEnd) is a compile-time handle; the runtime keys the
                // def by id but keeps the type name for 'is a AspectOfTheEnd'
                // checks. Older ASTs without the field fall back to the id.
                has(obj, "type_name") ? obj.get("type_name").getAsString()
                        : obj.get("id").getAsString());
    }

    /**
     * First-class inline handlers (W-inline-handlers): the additive
     * {@code "handlers"} object each declaration may carry, keyed by event
     * name to {@code {params:[...], body:{...}}}. Absent key -> empty map, so
     * handler-free declarations stay unchanged. Param names are the user's
     * binders in declaration order; the runtime dispatcher binds them
     * positionally to that event's arguments.
     */
    private static Map<String, net.swofty.model.InlineHandler> buildInlineHandlers(JsonObject obj) {
        if (!has(obj, "handlers")) {
            return Map.of();
        }
        Map<String, net.swofty.model.InlineHandler> handlers = new LinkedHashMap<>();
        for (Map.Entry<String, JsonElement> entry : obj.getAsJsonObject("handlers").entrySet()) {
            JsonObject h = entry.getValue().getAsJsonObject();
            List<String> params = new ArrayList<>();
            for (JsonElement param : optArray(h, "params")) {
                params.add(param.getAsString());
            }
            handlers.put(entry.getKey(), new net.swofty.model.InlineHandler(
                    optString(h, "self"), params, buildExecuteBlock(h.get("body"))));
        }
        return handlers;
    }

    /**
     * A declared tag value: scalars pass through scalarValue; lists and
     * compounds recurse into nested {@code List}/{@code Map} trees, which
     * ItemRegistry serializes to nested NBT (phase 9 §2).
     */
    private static Object tagValue(JsonElement element) {
        if (element.isJsonObject()) {
            JsonObject obj = element.getAsJsonObject();
            if (obj.has("kind")) {
                String kind = obj.get("kind").getAsString();
                if ("list".equals(kind)) {
                    List<Object> list = new ArrayList<>();
                    for (JsonElement item : obj.getAsJsonArray("items")) {
                        list.add(tagValue(item));
                    }
                    return list;
                }
                if ("map".equals(kind)) {
                    Map<String, Object> map = new LinkedHashMap<>();
                    for (Map.Entry<String, JsonElement> entry
                            : obj.getAsJsonObject("entries").entrySet()) {
                        map.put(entry.getKey(), tagValue(entry.getValue()));
                    }
                    return map;
                }
            }
        }
        return scalarValue(element);
    }

    /**
     * Declaration strings arrive as raw JSON strings or literal expression
     * nodes (the OCaml side emits `opt expr` for item names/descriptions).
     */
    private static String constString(JsonElement element) {
        if (element == null || element.isJsonNull()) {
            return null;
        }
        Object value = scalarValue(element);
        return value != null ? String.valueOf(value) : null;
    }

    /**
     * mob "id" { } declaration (design 5B): entity type, live-interpolated
     * name expression, health/damage/speed, ai kind, drops, handlers.
     */
    private static MobDefModel buildMob(JsonObject obj) {
        Expression name = null;
        if (has(obj, "name")) {
            JsonElement nameElement = obj.get("name");
            name = nameElement.isJsonObject()
                    ? buildExpression(nameElement.getAsJsonObject())
                    : new StringLiteral(nameElement.getAsString());
        }

        List<MobDropModel> drops = new ArrayList<>();
        for (JsonElement element : optArray(obj, "drops")) {
            JsonObject drop = element.getAsJsonObject();
            drops.add(new MobDropModel(
                    firstString(drop, "item", "id"),
                    scalarNumber(drop.get("chance")),
                    has(drop, "amount") ? (int) scalarNumber(drop.get("amount")) : 1));
        }

        return new MobDefModel(
                obj.get("id").getAsString(),
                obj.get("type").getAsString(),
                name,
                has(obj, "health") ? scalarNumber(obj.get("health")) : 20.0,
                has(obj, "damage") ? scalarNumber(obj.get("damage")) : 0.0,
                has(obj, "speed") ? scalarNumber(obj.get("speed")) : 0.1,
                has(obj, "ai") ? obj.get("ai").getAsString().toLowerCase() : "none",
                drops,
                has(obj, "on_spawn") ? buildExecuteBlock(obj.get("on_spawn")) : null,
                has(obj, "on_death") ? buildExecuteBlock(obj.get("on_death")) : null,
                has(obj, "on_damage") ? buildExecuteBlock(obj.get("on_damage"))
                        : has(obj, "on_damaged") ? buildExecuteBlock(obj.get("on_damaged")) : null,
                has(obj, "on_attack") ? buildExecuteBlock(obj.get("on_attack")) : null,
                has(obj, "on_hit") ? buildExecuteBlock(obj.get("on_hit")) : null,
                buildInlineHandlers(obj),
                buildMobTags(obj),
                !has(obj, "viewable") || obj.get("viewable").getAsBoolean(),
                // §2 nominal custom types: the Capitalized type name (Ghoul) is a
                // compile-time handle; the runtime keys the def by id but keeps
                // the type name for 'is a Ghoul' specialization checks. Older ASTs
                // without the field fall back to the id.
                has(obj, "type_name") ? obj.get("type_name").getAsString()
                        : obj.get("id").getAsString());
    }

    /**
     * Parse a mob {@code tags { ... }} block (W-viewers feature 2). Each entry is
     * emitted by the compiler as either:
     * <ul>
     *   <li>a TYPE declaration — {@code {"kind":"type","type":{"base":"MAP"|"LIST"|...}}}
     *       — seeded as an empty live container (map/list) or a none scalar; or</li>
     *   <li>a value init — {@code {"kind":"value","value":<literal>}} (item style) —
     *       seeded with the literal, its type inferred.</li>
     * </ul>
     * (A bare primitive/literal is tolerated as a value init for forward
     * compatibility.) Undeclared keys still work at runtime as freeform NBT tags.
     */
    private static Map<String, net.swofty.model.MobTagDecl> buildMobTags(JsonObject obj) {
        Map<String, net.swofty.model.MobTagDecl> tags = new LinkedHashMap<>();
        if (!has(obj, "tags")) {
            return tags;
        }
        for (Map.Entry<String, JsonElement> entry : obj.getAsJsonObject("tags").entrySet()) {
            String key = entry.getKey();
            JsonElement element = entry.getValue();
            if (element.isJsonObject() && element.getAsJsonObject().has("kind")
                    && "type".equals(element.getAsJsonObject().get("kind").getAsString())) {
                String base = element.getAsJsonObject().getAsJsonObject("type")
                        .get("base").getAsString();
                net.swofty.model.MobTagDecl.Kind kind = switch (base.toUpperCase()) {
                    case "MAP" -> net.swofty.model.MobTagDecl.Kind.MAP;
                    case "LIST" -> net.swofty.model.MobTagDecl.Kind.LIST;
                    default -> net.swofty.model.MobTagDecl.Kind.SCALAR;
                };
                tags.put(key, net.swofty.model.MobTagDecl.typed(key, kind));
            } else if (element.isJsonObject() && element.getAsJsonObject().has("kind")
                    && "value".equals(element.getAsJsonObject().get("kind").getAsString())) {
                tags.put(key, net.swofty.model.MobTagDecl.value(key,
                        scalarValue(element.getAsJsonObject().get("value"))));
            } else {
                tags.put(key, net.swofty.model.MobTagDecl.value(key, scalarValue(element)));
            }
        }
        return tags;
    }

    /** Declaration scalar: raw JSON primitive or a literal expression node. */
    private static Object scalarValue(JsonElement element) {
        if (element.isJsonPrimitive()) {
            var primitive = element.getAsJsonPrimitive();
            if (primitive.isBoolean()) {
                return primitive.getAsBoolean();
            }
            if (primitive.isNumber()) {
                double value = primitive.getAsDouble();
                return value == Math.rint(value) && !primitive.getAsString().contains(".")
                        ? (Object) (int) value : (Object) value;
            }
            return primitive.getAsString();
        }
        JsonObject obj = element.getAsJsonObject();
        String kind = obj.get("kind").getAsString();
        return switch (kind) {
            case "string" -> obj.get("value").getAsString();
            case "boolean" -> obj.get("value").getAsBoolean();
            case "number" -> obj.get("integer").getAsBoolean()
                    ? (Object) obj.get("value").getAsInt()
                    : (Object) obj.get("value").getAsDouble();
            case "unary" -> {
                // negative number literals arrive as unary minus
                Object operand = scalarValue(obj.getAsJsonObject("operand"));
                yield operand instanceof Integer i ? (Object) (-i)
                        : (Object) (-((Number) operand).doubleValue());
            }
            default -> throw new IllegalArgumentException(
                    "declaration values must be literals, got expression kind: " + kind);
        };
    }

    private static double scalarNumber(JsonElement element) {
        Object value = scalarValue(element);
        if (!(value instanceof Number number)) {
            throw new IllegalArgumentException("expected a number, got: " + value);
        }
        return number.doubleValue();
    }

    private static void buildCommands(JsonObject obj, List<Command> commands) {
        String permission = optString(obj, "permission");
        String description = optString(obj, "description");

        ExecuteBlock executeBlock = null;
        if (has(obj, "execute")) {
            executeBlock = buildExecuteBlock(obj.get("execute"));
            // debug-tracer handler identity: name it after the first command
            // name so handler enter/exit events read "command <name>"
            JsonArray names = obj.getAsJsonArray("names");
            String primary = names.size() > 0 ? names.get(0).getAsString() : "?";
            executeBlock.setHandler("command " + primary, currentFile,
                    firstStatementLine(executeBlock));
        }

        List<Variable> arguments = new ArrayList<>();
        for (JsonElement element : optArray(obj, "arguments")) {
            JsonObject arg = element.getAsJsonObject();
            Variable variable = new Variable(arg.get("name").getAsString(),
                    buildDataType(arg.getAsJsonObject("type")));
            String defaultValue = optString(arg, "default");
            if (defaultValue != null) {
                variable.setDefault(defaultValue);
            }
            arguments.add(variable);
        }

        // One Command per name; aliases share the same ExecuteBlock instance
        for (JsonElement nameElement : obj.getAsJsonArray("names")) {
            Command command = new Command(nameElement.getAsString());
            command.setPermission(permission != null ? permission : "");
            command.setDescription(description != null ? description : "");
            for (Variable argument : arguments) {
                command.addArgument(argument);
            }
            if (executeBlock != null) {
                command.setExecuteBlock(executeBlock);
            }
            commands.add(command);
        }
    }

    private static Event buildEvent(JsonObject obj) {
        Event event = new Event(obj.get("name").getAsString());
        event.setPriority(obj.get("priority").getAsInt());
        // OOP receiver model (additive keys): a Capitalized base-type receiver
        // method carries its receiver type + the user's positional binder names
        // so the runtime binds `this` + args instead of the flat sender/alias
        // scheme. Absent on legacy flat handlers, which stay on the old path.
        if (has(obj, "receiver")) {
            event.setReceiver(obj.get("receiver").getAsString());
        }
        if (has(obj, "self")) {
            event.setSelf(obj.get("self").getAsString());
        }
        if (has(obj, "params")) {
            List<String> params = new ArrayList<>();
            for (JsonElement param : obj.getAsJsonArray("params")) {
                params.add(param.getAsString());
            }
            event.setParams(params);
        }
        if (has(obj, "execute")) {
            ExecuteBlock block = buildExecuteBlock(obj.get("execute"));
            block.setHandler("event " + event.getName(), currentFile,
                    firstStatementLine(block));
            event.setExecuteBlock(block);
        }
        return event;
    }

    /** Declaration line for a handler event: its first statement's line. */
    private static int firstStatementLine(ExecuteBlock block) {
        if (!block.getStatements().isEmpty()
                && block.getStatements().get(0) instanceof AbstractAstNode node) {
            return node.getLine();
        }
        return -1;
    }

    private static SwoftFunction buildFunction(JsonObject obj) {
        boolean async = optBoolean(obj, "async");
        ExecuteBlock body = buildExecuteBlock(obj.get("body"));
        body.setAsync(async || body.isAsync());
        if (currentModule == null) {
            return new SwoftFunction(obj.get("name").getAsString(), buildParams(obj), body,
                    body.isAsync());
        }
        return new SwoftFunction(obj.get("name").getAsString(), buildParams(obj), body,
                body.isAsync(), currentModule, optBoolean(obj, "exported"));
    }

    private static List<SwoftFunction.Param> buildParams(JsonObject obj) {
        List<SwoftFunction.Param> params = new ArrayList<>();
        for (JsonElement element : optArray(obj, "params")) {
            JsonObject param = element.getAsJsonObject();
            DataType type = has(param, "type") ? buildDataType(param.getAsJsonObject("type")) : null;
            params.add(new SwoftFunction.Param(param.get("name").getAsString(), type));
        }
        return params;
    }

    private static DataType buildDataType(JsonObject obj) {
        String baseName = obj.get("base").getAsString();
        // A nominal struct / custom type is emitted with its Capitalized name
        // verbatim (e.g. "Guild", "Point") instead of a builtin base keyword;
        // carry it as a STRUCT base with the name attached so the struct
        // registry and persistence layer can resolve it.
        BaseType baseType;
        try {
            baseType = BaseType.valueOf(baseName);
        } catch (IllegalArgumentException notBuiltin) {
            DataType nominal = new DataType(BaseType.STRUCT);
            nominal.setTypeName(baseName);
            return nominal;
        }
        DataType dataType = new DataType(baseType);
        BaseType base = dataType.getBaseType();
        if (base == BaseType.EITHER || base == BaseType.OPTIONAL || base == BaseType.LIST
                || base == BaseType.MAP) {
            // An Integer-keyed map<K, V> emits its key type as a sibling
            // "key_type" field (the value type stays in "subtypes"); load it
            // FIRST so the DataType has subTypes=[K, V] — the shape
            // PersistStore.mapKeyType/mapElementType (and the harness) expect.
            // String-keyed maps emit no key_type and stay subTypes=[V].
            if (base == BaseType.MAP && has(obj, "key_type")) {
                dataType.addSubType(buildDataType(obj.getAsJsonObject("key_type")));
            }
            for (JsonElement element : optArray(obj, "subtypes")) {
                dataType.addSubType(buildDataType(element.getAsJsonObject()));
            }
        }
        return dataType;
    }

    /**
     * v1 execute blocks are bare statement arrays; v2 blocks may be objects
     * carrying the async flag: {"async": bool, "statements": [...]}
     */
    private static ExecuteBlock buildExecuteBlock(JsonElement element) {
        if (element.isJsonArray()) {
            return buildStatements(element.getAsJsonArray(), false);
        }
        JsonObject obj = element.getAsJsonObject();
        JsonArray statements = has(obj, "statements")
                ? obj.getAsJsonArray("statements") : optArray(obj, "body");
        return buildStatements(statements, optBoolean(obj, "async"));
    }

    private static ExecuteBlock buildStatements(JsonArray statements, boolean async) {
        ExecuteBlock block = new ExecuteBlock();
        block.setAsync(async);
        // bundle loads tag every block with its owning module so execution
        // contexts can enter the module's scope
        block.setModule(currentModule);
        for (JsonElement element : statements) {
            block.addStatement(buildStatement(element.getAsJsonObject()));
        }
        return block;
    }

    private static Statement buildStatement(JsonObject obj) {
        Statement statement = buildStatementNode(obj);
        applyPosition(statement, obj);
        // thread the owning file + statement kind onto the node so the debug
        // tracer can emit them per executed statement (zero cost when off)
        if (statement instanceof AbstractAstNode astNode) {
            astNode.setFile(currentFile);
            if (has(obj, "kind")) {
                astNode.setKind(obj.get("kind").getAsString());
            }
        }
        return statement;
    }

    private static Statement buildStatementNode(JsonObject obj) {
        String kind = obj.get("kind").getAsString();
        switch (kind) {
            case "send":
                return new SendCommand(buildExpression(obj.getAsJsonObject("message")),
                        has(obj, "target") ? buildExpression(obj.getAsJsonObject("target")) : null);
            case "broadcast":
                return new SendCommand(buildExpression(obj.getAsJsonObject("message")),
                        new StringLiteral("all"));
            case "teleport":
                return new TeleportCommand(buildExpression(obj.getAsJsonObject("entity")),
                        buildExpression(obj.getAsJsonObject("target")));
            case "halt":
                return new HaltCommand();
            case "cancel_event":
                return new CancelEventStatement();
            case "if":
                return new IfStatement(buildExpression(obj.getAsJsonObject("condition")),
                        buildStatement(obj.getAsJsonObject("then")),
                        has(obj, "else") ? buildStatement(obj.getAsJsonObject("else")) : null);
            case "block": {
                BlockStatement block = new BlockStatement();
                for (JsonElement element : obj.getAsJsonArray("statements")) {
                    block.addStatement(buildStatement(element.getAsJsonObject()));
                }
                return block;
            }
            case "assign":
                return new VariableAssignment(obj.get("target").getAsString(),
                        buildExpression(obj.getAsJsonObject("value")));
            case "set_prop":
                return new SetPropertyStatement(buildExpression(obj.getAsJsonObject("target")),
                        obj.get("name").getAsString(),
                        buildExpression(obj.getAsJsonObject("value")));
            case "persist_set":
                return new PersistSetStatement(obj.get("name").getAsString(),
                        has(obj, "subject") ? buildExpression(obj.getAsJsonObject("subject")) : null,
                        buildExpression(obj.getAsJsonObject("value")));
            case "loop":
                return new LoopStatement(buildExpression(obj.getAsJsonObject("count")),
                        optString(obj, "var"),
                        buildStatement(obj.getAsJsonObject("body")));
            case "while":
                return new WhileStatement(buildExpression(obj.getAsJsonObject("condition")),
                        buildStatement(obj.getAsJsonObject("body")));
            case "foreach":
                // loop <iterable> as <var> [with limit] - list/collection loop
                return new ForEachStatement(obj.get("var").getAsString(),
                        optString(obj, "value"),
                        buildExpression(obj.getAsJsonObject("iterable")),
                        has(obj, "limit") ? buildExpression(obj.getAsJsonObject("limit")) : null,
                        buildStatement(obj.getAsJsonObject("body")));
            case "foreach_map":
                // loop <map> as <key> -> <value> - map entry loop binding both
                // the String key and the V value per entry (design phase-10 §1)
                return new ForEachStatement(obj.get("key").getAsString(),
                        obj.get("value").getAsString(),
                        buildExpression(obj.getAsJsonObject("map")),
                        null,
                        buildStatement(obj.getAsJsonObject("body")));
            case "set_index":
                // set target[key] to value (map_set / list slot write)
                return new IndexAssignStatement(
                        buildExpression(obj.getAsJsonObject("target")),
                        buildExpression(obj.getAsJsonObject("key")),
                        buildExpression(obj.getAsJsonObject("value")));
            case "call":
                return new FunctionCallStatement(obj.get("name").getAsString(),
                        buildExpressionList(obj.getAsJsonArray("args")));
            case "call_original":
                // `call original method`: base runs with the current bound vars
                return new CallOriginalStatement();
            case "method_call_stmt":
                // <receiver>.<name>(<args>) in-place mutating collection method
                return new net.swofty.nativebridge.execution.commands.MethodCallStatement(
                        buildExpression(obj.getAsJsonObject("receiver")),
                        obj.get("name").getAsString(),
                        buildExpressionList(obj.getAsJsonArray("args")));
            case "return":
                return new ReturnStatement(
                        has(obj, "value") ? buildExpression(obj.getAsJsonObject("value")) : null);
            case "wait":
                return new WaitStatement(buildExpression(obj.getAsJsonObject("amount")),
                        WaitStatement.Unit.valueOf(obj.get("unit").getAsString().toUpperCase()));
            case "spawn": {
                JsonObject call = obj.getAsJsonObject("call");
                return new SpawnStatement(call.get("name").getAsString(),
                        buildExpressionList(call.getAsJsonArray("args")));
            }
            case "async_block":
                return new AsyncBlockStatement(buildStatements(obj.getAsJsonArray("body"), true));
            case "open_gui":
                return new OpenGuiStatement(obj.get("name").getAsString(),
                        buildExpression(obj.getAsJsonObject("target")),
                        buildExpressionMap(obj), false);
            case "replace_gui":
                return new OpenGuiStatement(obj.get("name").getAsString(),
                        buildExpression(obj.getAsJsonObject("target")),
                        buildExpressionMap(obj), true);
            case "close_gui":
                return new CloseGuiStatement(buildExpression(obj.getAsJsonObject("target")));
            case "gui_back":
                return new GuiBackStatement(buildExpression(obj.getAsJsonObject("target")));
            case "line":
                return new LineStatement(buildExpression(obj.getAsJsonObject("text")));
            case "blank":
                return new LineStatement(null);
            case "entry":
                return new EntryStatement(buildExpression(obj.getAsJsonObject("text")),
                        buildSkin(obj.getAsJsonObject("skin")));
            case "fill":
                return new EntryStatement(null, buildSkin(obj.getAsJsonObject("skin")));
            case "show_scoreboard":
                return new ShowScoreboardStatement(obj.get("name").getAsString(),
                        buildExpression(obj.getAsJsonObject("target")));
            case "hide_scoreboard":
                return new HideScoreboardStatement(buildExpression(obj.getAsJsonObject("target")));
            case "update_scoreboard":
                return new UpdateScoreboardStatement(buildExpression(obj.getAsJsonObject("target")));
            case "show_tablist":
                return new ShowTablistStatement(obj.get("name").getAsString(),
                        buildExpression(obj.getAsJsonObject("target")));
            case "hide_tablist":
                return new HideTablistStatement(buildExpression(obj.getAsJsonObject("target")));
            case "set_tablist_part":
                return new SetTablistPartStatement(
                        SetTablistPartStatement.Part.valueOf(obj.get("part").getAsString().toUpperCase()),
                        buildExpression(obj.getAsJsonObject("value")),
                        buildExpression(obj.getAsJsonObject("target")));
            case "title":
                return new TitleStatement(buildExpression(obj.getAsJsonObject("title")),
                        has(obj, "subtitle") ? buildExpression(obj.getAsJsonObject("subtitle")) : null,
                        buildExpression(obj.getAsJsonObject("target")),
                        optInt(obj, "fade_in"), optInt(obj, "stay"), optInt(obj, "fade_out"));
            case "clear_title":
                return new ClearTitleStatement(buildExpression(obj.getAsJsonObject("target")));
            case "actionbar":
                return new ActionbarStatement(buildExpression(obj.getAsJsonObject("text")),
                        buildExpression(obj.getAsJsonObject("target")),
                        optInt(obj, "duration"));
            case "show_bossbar":
                return new ShowBossbarStatement(obj.get("name").getAsString(),
                        buildExpression(obj.getAsJsonObject("target")));
            case "hide_bossbar":
                return new HideBossbarStatement(obj.get("name").getAsString(),
                        buildExpression(obj.getAsJsonObject("target")));
            case "set_bossbar_part":
                return new SetBossbarPartStatement(obj.get("name").getAsString(),
                        SetBossbarPartStatement.Part.valueOf(obj.get("part").getAsString().toUpperCase()),
                        buildExpression(obj.getAsJsonObject("value")),
                        buildExpression(obj.getAsJsonObject("target")));
            case "show_entity":
                // show <entity> to <player|list<Player>|all> (W-viewers). The
                // UI show-verbs keep their own kinds; this fires only when the
                // object of `show` is an entity expression.
                return new net.swofty.nativebridge.execution.commands.entities
                        .ShowEntityStatement(
                        buildExpression(obj.getAsJsonObject("entity")),
                        buildExpression(obj.getAsJsonObject("target")));
            case "hide_entity":
                // hide <entity> from <player|list<Player>|all> (W-viewers).
                return new net.swofty.nativebridge.execution.commands.entities
                        .HideEntityStatement(
                        buildExpression(obj.getAsJsonObject("entity")),
                        buildExpression(obj.getAsJsonObject("target")));
            case "set_entity_name":
                // set name of <entity> to <String> for <player> (W-viewers,
                // per-viewer overhead nametag).
                return new net.swofty.nativebridge.execution.commands.entities
                        .SetEntityNameForStatement(
                        buildExpression(obj.getAsJsonObject("entity")),
                        buildExpression(obj.getAsJsonObject("value")),
                        buildExpression(obj.getAsJsonObject("viewer")));
            case "show_hologram":
                return new ShowHologramStatement(obj.get("name").getAsString(),
                        buildExpression(obj.getAsJsonObject("target")));
            case "hide_hologram":
                return new HideHologramStatement(obj.get("name").getAsString(),
                        buildExpression(obj.getAsJsonObject("target")));
            case "move_hologram":
                return new MoveHologramStatement(obj.get("name").getAsString(),
                        buildExpression(obj.getAsJsonObject("to")));
            case "set_hologram_line":
                return new SetHologramLineStatement(obj.get("name").getAsString(),
                        buildExpression(obj.getAsJsonObject("index")),
                        buildExpression(obj.getAsJsonObject("value")));
            case "remove_hologram":
                return new RemoveHologramStatement(obj.get("name").getAsString());
            case "set_npc_skin":
                return new SetNpcSkinStatement(obj.get("name").getAsString(),
                        buildNpcSkin(obj.getAsJsonObject("skin")));
            case "set_npc_name":
                return new SetNpcNameStatement(obj.get("name").getAsString(),
                        buildExpression(obj.getAsJsonObject("value")));
            case "set_npc_location":
                return new SetNpcLocationStatement(obj.get("name").getAsString(),
                        buildExpression(obj.getAsJsonObject("value")));
            case "remove_npc":
                return new RemoveNpcStatement(obj.get("name").getAsString());
            case "show_npc":
                // show npc "name" to <player|list<Player>|all> (W-viewers §2).
                // Routes through the same Viewable add-viewer path as the
                // generic `show <entity>` verb, keyed by npc name.
                return new net.swofty.nativebridge.execution.commands.npcs
                        .ShowNpcStatement(obj.get("name").getAsString(),
                        buildExpression(obj.getAsJsonObject("target")));
            case "hide_npc":
                // hide npc "name" from <player|list<Player>|all> (W-viewers §2).
                return new net.swofty.nativebridge.execution.commands.npcs
                        .HideNpcStatement(obj.get("name").getAsString(),
                        buildExpression(obj.getAsJsonObject("target")));
            case "give_item":
                return new GiveItemStatement(buildStringOrExpression(obj.get("id")),
                        buildExpression(obj.getAsJsonObject("target")),
                        has(obj, "amount") ? buildExpression(obj.getAsJsonObject("amount")) : null);
            case "spawn_mob":
                return new SpawnMobStatement(buildStringOrExpression(obj.get("id")),
                        buildExpression(has(obj, "at")
                                ? obj.getAsJsonObject("at") : obj.getAsJsonObject("location")),
                        optString(obj, "as"));
            case "despawn_mob":
                return new DespawnMobStatement(buildExpression(has(obj, "target")
                        ? obj.getAsJsonObject("target") : obj.getAsJsonObject("mob")));
            // ---------- phase-7 statements (entity system) ----------
            case "spawn_entity":
                return new net.swofty.nativebridge.execution.commands.entities
                        .SpawnEntityStatement(
                        buildStringOrExpression(has(obj, "type") ? obj.get("type")
                                : obj.get("id")),
                        buildExpression(has(obj, "at")
                                ? obj.getAsJsonObject("at") : obj.getAsJsonObject("location")),
                        optString(obj, "as"));
            case "remove_entity":
                return new net.swofty.nativebridge.execution.commands.entities
                        .RemoveEntityStatement(
                        firstExpr(obj, "target", "entity"));
            case "mount":
            case "mount_entity":
                return new net.swofty.nativebridge.execution.commands.entities
                        .MountEntityStatement(
                        firstExpr(obj, "entity", "rider", "target"),
                        firstExpr(obj, "on", "vehicle", "anchor"));
            case "dismount":
            case "dismount_entity":
                return new net.swofty.nativebridge.execution.commands.entities
                        .DismountEntityStatement(
                        firstExpr(obj, "target", "entity", "rider"));
            case "launch_projectile":
                return new net.swofty.nativebridge.execution.commands.entities
                        .LaunchProjectileStatement(
                        buildStringOrExpression(has(obj, "type") ? obj.get("type")
                                : obj.get("id")),
                        firstExpr(obj, "from", "shooter"),
                        firstExpr(obj, "velocity", "with_velocity"),
                        firstExpr(obj, "speed", "with_speed"),
                        optString(obj, "as"));
            case "set_nametag":
                return new SetNametagStatement(
                        nametagPart(has(obj, "part") ? obj.get("part").getAsString() : "text"),
                        buildExpression(obj.getAsJsonObject("target")),
                        buildExpression(obj.getAsJsonObject("value")),
                        has(obj, "viewer") ? buildExpression(obj.getAsJsonObject("viewer")) : null);
            case "reset_nametag":
                return new ResetNametagStatement(
                        buildExpression(obj.getAsJsonObject("target")),
                        has(obj, "viewer") ? buildExpression(obj.getAsJsonObject("viewer")) : null);
            case "dispense_from":
                return new net.swofty.blocks.DispenseFromStatement(
                        buildExpression(obj.getAsJsonObject("from")));
            case "send_packet":
                return new SendPacketStatement(obj.get("name").getAsString(),
                        buildFieldMap(obj.get("fields")),
                        has(obj, "target") ? buildExpression(obj.getAsJsonObject("target")) : null);
            case "cancel_packet":
                return new CancelPacketStatement();
            // ---------- phase-6 statements (design 6B/6D) ----------
            case "show_display":
                return new net.swofty.nativebridge.execution.commands.displays
                        .ShowDisplayStatement(
                        buildExpression(obj.getAsJsonObject("display")),
                        has(obj, "viewer") ? buildExpression(obj.getAsJsonObject("viewer"))
                                : has(obj, "target")
                                        ? buildExpression(obj.getAsJsonObject("target")) : null);
            case "hide_display":
                return new net.swofty.nativebridge.execution.commands.displays
                        .HideDisplayStatement(
                        buildExpression(obj.getAsJsonObject("display")),
                        has(obj, "viewer") ? buildExpression(obj.getAsJsonObject("viewer"))
                                : has(obj, "target")
                                        ? buildExpression(obj.getAsJsonObject("target")) : null);
            case "mount_display":
                return new net.swofty.nativebridge.execution.commands.displays
                        .MountDisplayStatement(
                        buildExpression(obj.getAsJsonObject("display")),
                        buildExpression(has(obj, "on") ? obj.getAsJsonObject("on")
                                : has(obj, "entity") ? obj.getAsJsonObject("entity")
                                        : obj.getAsJsonObject("anchor")));
            case "unmount_display":
                return new net.swofty.nativebridge.execution.commands.displays
                        .UnmountDisplayStatement(
                        buildExpression(obj.getAsJsonObject("display")));
            case "teleport_display":
                return new net.swofty.nativebridge.execution.commands.displays
                        .TeleportDisplayStatement(
                        buildExpression(obj.getAsJsonObject("display")),
                        buildExpression(has(obj, "to") ? obj.getAsJsonObject("to")
                                : obj.getAsJsonObject("location")));
            case "destroy_display":
                return new net.swofty.nativebridge.execution.commands.displays
                        .DestroyDisplayStatement(
                        buildExpression(obj.getAsJsonObject("display")));

            case "reply":
                return new net.swofty.nativebridge.execution.commands.http.ReplyStatement(
                        has(obj, "code") ? buildExpression(obj.getAsJsonObject("code")) : null,
                        has(obj, "body") ? buildExpression(obj.getAsJsonObject("body"))
                                : has(obj, "with")
                                        ? buildExpression(obj.getAsJsonObject("with"))
                                        : has(obj, "value")
                                                ? buildExpression(obj.getAsJsonObject("value"))
                                                : null);

            case "play_song":
                return new net.swofty.nativebridge.execution.commands.music.PlaySongStatement(
                        buildStringOrExpression(obj.get("song")),
                        has(obj, "target") ? buildExpression(obj.getAsJsonObject("target")) : null,
                        firstExpr(obj, "at_tick", "tick"),
                        has(obj, "volume") ? buildExpression(obj.getAsJsonObject("volume")) : null,
                        has(obj, "radius") ? buildExpression(obj.getAsJsonObject("radius")) : null,
                        has(obj, "at") ? buildExpression(obj.getAsJsonObject("at")) : null);
            case "broadcast_song":
                return new net.swofty.nativebridge.execution.commands.music
                        .BroadcastSongStatement(
                        buildStringOrExpression(obj.get("song")),
                        has(obj, "volume") ? buildExpression(obj.getAsJsonObject("volume")) : null);
            case "pause_song":
                return songControl(obj,
                        net.swofty.nativebridge.execution.commands.music
                                .SongControlStatement.Action.PAUSE);
            case "resume_song":
                return songControl(obj,
                        net.swofty.nativebridge.execution.commands.music
                                .SongControlStatement.Action.RESUME);
            case "stop_song":
                return songControl(obj,
                        net.swofty.nativebridge.execution.commands.music
                                .SongControlStatement.Action.STOP);
            case "set_song_volume":
            case "song_volume":
                return songControl(obj,
                        net.swofty.nativebridge.execution.commands.music
                                .SongControlStatement.Action.VOLUME);
            case "fade_song":
                return songControl(obj,
                        net.swofty.nativebridge.execution.commands.music
                                .SongControlStatement.Action.FADE);

            case "set_block":
                return new net.swofty.nativebridge.execution.commands.blocks.SetBlockStatement(
                        buildExpression(has(obj, "at") ? obj.getAsJsonObject("at")
                                : obj.getAsJsonObject("location")),
                        buildStringOrExpression(has(obj, "block") ? obj.get("block")
                                : obj.get("value")),
                        has(obj, "world") ? buildExpression(obj.getAsJsonObject("world")) : null);
            case "fill_blocks":
                return new net.swofty.nativebridge.execution.commands.blocks.FillBlocksStatement(
                        buildExpression(obj.getAsJsonObject("from")),
                        buildExpression(obj.getAsJsonObject("to")),
                        buildStringOrExpression(has(obj, "block") ? obj.get("block")
                                : obj.get("with")),
                        has(obj, "world") ? buildExpression(obj.getAsJsonObject("world")) : null);

            case "play_sound":
                return new net.swofty.nativebridge.execution.commands.sounds.PlaySoundStatement(
                        buildStringOrExpression(has(obj, "sound") ? obj.get("sound")
                                : obj.get("name")),
                        has(obj, "target") ? buildExpression(obj.getAsJsonObject("target")) : null,
                        has(obj, "at") ? buildExpression(obj.getAsJsonObject("at")) : null,
                        has(obj, "volume") ? buildExpression(obj.getAsJsonObject("volume")) : null,
                        has(obj, "pitch") ? buildExpression(obj.getAsJsonObject("pitch")) : null);
            case "stop_sound":
                return new net.swofty.nativebridge.execution.commands.sounds.StopSoundStatement(
                        has(obj, "sound") ? buildStringOrExpression(obj.get("sound")) : null,
                        has(obj, "target") ? buildExpression(obj.getAsJsonObject("target")) : null);

            case "spawn_particle":
                return new net.swofty.nativebridge.execution.commands.particles
                        .SpawnParticleStatement(
                        buildStringOrExpression(has(obj, "particle") ? obj.get("particle")
                                : obj.get("name")),
                        buildExpression(has(obj, "at") ? obj.getAsJsonObject("at")
                                : obj.getAsJsonObject("location")),
                        has(obj, "count") ? buildExpression(obj.getAsJsonObject("count")) : null,
                        firstExpr(obj, "offset_x", "dx"),
                        firstExpr(obj, "offset_y", "dy"),
                        firstExpr(obj, "offset_z", "dz"),
                        has(obj, "speed") ? buildExpression(obj.getAsJsonObject("speed")) : null,
                        has(obj, "viewer") ? buildExpression(obj.getAsJsonObject("viewer"))
                                : has(obj, "target")
                                        ? buildExpression(obj.getAsJsonObject("target")) : null);

            case "create_world":
                return new net.swofty.nativebridge.execution.commands.worlds
                        .CreateWorldStatement(
                        buildStringOrExpression(obj.get("name")),
                        buildExpression(has(obj, "loader") ? obj.getAsJsonObject("loader")
                                : obj.getAsJsonObject("with")),
                        optBoolean(obj, "readonly"));
            case "load_world":
                return new net.swofty.nativebridge.execution.commands.worlds.LoadWorldStatement(
                        buildStringOrExpression(obj.get("name")),
                        buildExpression(has(obj, "loader") ? obj.getAsJsonObject("loader")
                                : obj.getAsJsonObject("with")));
            case "unload_world":
                return new net.swofty.nativebridge.execution.commands.worlds
                        .UnloadWorldStatement(
                        buildStringOrExpression(obj.get("name")),
                        !has(obj, "save") || obj.get("save").getAsBoolean(),
                        firstExpr(obj, "teleport", "teleport_to", "teleporting_to"));
            case "save_world":
                return new net.swofty.nativebridge.execution.commands.worlds.SaveWorldStatement(
                        buildStringOrExpression(obj.get("name")));
            case "clone_world":
                return new net.swofty.nativebridge.execution.commands.worlds
                        .CloneWorldStatement(
                        buildStringOrExpression(has(obj, "from") ? obj.get("from")
                                : obj.get("source")),
                        buildStringOrExpression(has(obj, "to") ? obj.get("to")
                                : obj.get("dest")),
                        buildExpression(has(obj, "loader") ? obj.getAsJsonObject("loader")
                                : obj.getAsJsonObject("with")));
            case "delete_world":
                return new net.swofty.nativebridge.execution.commands.worlds
                        .DeleteWorldStatement(
                        buildStringOrExpression(obj.get("name")),
                        buildExpression(has(obj, "loader") ? obj.getAsJsonObject("loader")
                                : obj.getAsJsonObject("with")));
            case "import_world":
            case "import_anvil_world":
                return new net.swofty.nativebridge.execution.commands.worlds
                        .ImportWorldStatement(
                        buildStringOrExpression(obj.get("path")),
                        buildStringOrExpression(has(obj, "as") ? obj.get("as")
                                : obj.get("name")),
                        buildExpression(has(obj, "loader") ? obj.getAsJsonObject("loader")
                                : obj.getAsJsonObject("with")));

            case "set_motd":
            case "set_server_motd":
                return new net.swofty.nativebridge.execution.commands.SetMotdStatement(
                        buildExpression(has(obj, "value") ? obj.getAsJsonObject("value")
                                : obj.getAsJsonObject("motd")));

            case "show_toast":
                return new net.swofty.nativebridge.execution.commands.toasts
                        .ShowToastStatement(
                        buildExpression(obj.getAsJsonObject("title")),
                        has(obj, "description")
                                ? buildExpression(obj.getAsJsonObject("description")) : null,
                        has(obj, "icon") ? buildStringOrExpression(obj.get("icon")) : null,
                        optString(obj, "frame"),
                        has(obj, "target") ? buildExpression(obj.getAsJsonObject("target")) : null);

            case "draw_pixel":
                return drawStatement(obj,
                        net.swofty.nativebridge.execution.commands.maps.DrawStatement.Op.PIXEL);
            case "draw_rect":
                return drawStatement(obj,
                        net.swofty.nativebridge.execution.commands.maps.DrawStatement.Op.RECT);
            case "draw_text":
                return drawStatement(obj,
                        net.swofty.nativebridge.execution.commands.maps.DrawStatement.Op.TEXT);
            case "give_map":
                return new net.swofty.nativebridge.execution.commands.maps.GiveMapStatement(
                        buildExpression(obj.getAsJsonObject("canvas")),
                        has(obj, "target") ? buildExpression(obj.getAsJsonObject("target")) : null);

            case "cancel_schedule":
                return new net.swofty.nativebridge.execution.commands.sched
                        .CancelScheduleStatement(
                        buildExpression(has(obj, "schedule") ? obj.getAsJsonObject("schedule")
                                : obj.getAsJsonObject("target")));
            case "repeat": {
                // repeat N times [every dur] { body } (scheduler v2)
                JsonArray repeatBody = has(obj, "body") ? obj.getAsJsonArray("body")
                        : obj.getAsJsonArray("statements");
                return new net.swofty.nativebridge.execution.commands.sched.RepeatStatement(
                        buildExpression(has(obj, "count") ? obj.getAsJsonObject("count")
                                : obj.getAsJsonObject("times")),
                        durationTicks(obj, "every", "interval"),
                        buildStatements(repeatBody, true),
                        optString(obj, "name"));
            }
            case "stop":
                // stop (scheduler v2): cancel the enclosing schedule/repeat
                return new net.swofty.nativebridge.execution.commands.sched.StopStatement();

            // ---------- W-tasks: per-object task registry ----------
            case "task_set":
                // set <obj>.tasks.<id> to schedule ...
                return new net.swofty.nativebridge.execution.commands.tasks
                        .TaskSetStatement(
                        buildExpression(obj.getAsJsonObject("owner")),
                        obj.get("id").getAsString(),
                        buildExpression(obj.getAsJsonObject("value")));
            case "task_cancel":
                // cancel/stop <obj>.tasks.<id>
                return new net.swofty.nativebridge.execution.commands.tasks
                        .TaskCancelStatement(
                        buildExpression(obj.getAsJsonObject("owner")),
                        obj.get("id").getAsString());
            case "place":
                // place <Block|"id"> at <location>
                return new net.swofty.nativebridge.execution.commands.blocks
                        .PlaceBlockStatement(
                        buildStringOrExpression(obj.get("block")),
                        buildExpression(obj.getAsJsonObject("location")));
            case "remove_block":
                // remove block at <location> (also cancels that position's tasks)
                return new net.swofty.nativebridge.execution.commands.blocks
                        .RemoveBlockStatement(
                        buildExpression(obj.getAsJsonObject("location")));

            case "belowname":
                return new BelownameStatement(BelownameStatement.Action.TEXT,
                        buildExpression(obj.getAsJsonObject("text")),
                        buildExpression(obj.getAsJsonObject("target")));
            case "set_belowname_score":
                return new BelownameStatement(BelownameStatement.Action.SCORE,
                        buildExpression(obj.getAsJsonObject("value")),
                        buildExpression(obj.getAsJsonObject("target")));
            case "clear_belowname":
                return new BelownameStatement(BelownameStatement.Action.CLEAR, null,
                        buildExpression(obj.getAsJsonObject("target")));

            // ---------- W-pvp: attribute modifiers + combat effect verbs ------
            case "add_modifier":
                return new net.swofty.nativebridge.execution.commands.combat
                        .AddModifierStatement(
                        buildExpression(obj.getAsJsonObject("id")),
                        buildExpression(obj.getAsJsonObject("entity")),
                        obj.get("attribute").getAsString(),
                        buildExpression(obj.getAsJsonObject("amount")),
                        obj.get("operation").getAsString());
            case "remove_modifier":
                return new net.swofty.nativebridge.execution.commands.combat
                        .RemoveModifierStatement(
                        buildExpression(obj.getAsJsonObject("id")),
                        buildExpression(obj.getAsJsonObject("entity")),
                        obj.get("attribute").getAsString());
            case "damage":
                return new net.swofty.nativebridge.execution.commands.combat
                        .DamageStatement(
                        buildExpression(obj.getAsJsonObject("target")),
                        buildExpression(obj.getAsJsonObject("amount")),
                        has(obj, "damage_type")
                                ? buildExpression(obj.getAsJsonObject("damage_type")) : null,
                        has(obj, "source")
                                ? buildExpression(obj.getAsJsonObject("source")) : null);
            case "knock":
                return new net.swofty.nativebridge.execution.commands.combat
                        .KnockStatement(
                        buildExpression(obj.getAsJsonObject("target")),
                        buildExpression(obj.getAsJsonObject("from")),
                        has(obj, "strength")
                                ? buildExpression(obj.getAsJsonObject("strength")) : null);
            case "apply_effect":
                return new net.swofty.nativebridge.execution.commands.combat
                        .ApplyEffectStatement(
                        buildExpression(obj.getAsJsonObject("effect")),
                        buildExpression(obj.getAsJsonObject("amplifier")),
                        buildExpression(obj.getAsJsonObject("entity")),
                        buildExpression(obj.getAsJsonObject("duration")));
            case "remove_effect":
                return new net.swofty.nativebridge.execution.commands.combat
                        .RemoveEffectStatement(
                        buildExpression(obj.getAsJsonObject("effect")),
                        buildExpression(obj.getAsJsonObject("entity")));
            case "shoot":
                return new net.swofty.nativebridge.execution.commands.combat
                        .ShootStatement(
                        buildExpression(obj.getAsJsonObject("projectile")),
                        buildExpression(obj.getAsJsonObject("from")),
                        has(obj, "velocity")
                                ? buildExpression(obj.getAsJsonObject("velocity")) : null,
                        has(obj, "shooter")
                                ? buildExpression(obj.getAsJsonObject("shooter")) : null);
            default:
                throw new IllegalArgumentException("Unknown statement kind: " + kind);
        }
    }

    /** First present key of an alias set, as an expression. */
    private static Expression firstExpr(JsonObject obj, String... keys) {
        for (String key : keys) {
            if (has(obj, key)) {
                return buildExpression(obj.getAsJsonObject(key));
            }
        }
        return null;
    }

    private static Statement songControl(JsonObject obj,
            net.swofty.nativebridge.execution.commands.music.SongControlStatement.Action action) {
        // fade duration: the emitter writes "ticks" as a raw int; accept
        // expression forms under the alias keys too
        Expression duration = null;
        if (has(obj, "ticks") && obj.get("ticks").isJsonPrimitive()) {
            duration = new NumberLiteral(obj.get("ticks").getAsDouble(), true);
        } else {
            duration = firstExpr(obj, "ticks", "duration_ticks", "duration", "over");
        }
        return new net.swofty.nativebridge.execution.commands.music.SongControlStatement(
                action,
                has(obj, "target") ? buildExpression(obj.getAsJsonObject("target")) : null,
                firstExpr(obj, "volume", "value"),
                duration);
    }

    private static Statement drawStatement(JsonObject obj,
            net.swofty.nativebridge.execution.commands.maps.DrawStatement.Op op) {
        return new net.swofty.nativebridge.execution.commands.maps.DrawStatement(
                op,
                buildExpression(obj.getAsJsonObject("canvas")),
                firstExpr(obj, "x", "x1"),
                firstExpr(obj, "y", "y1"),
                firstExpr(obj, "x2"),
                firstExpr(obj, "y2"),
                firstExpr(obj, "width", "w"),
                firstExpr(obj, "height", "h"),
                firstExpr(obj, "text", "value"),
                firstExpr(obj, "color"));
    }

    /**
     * Durations in declarations/expressions arrive as ticks
     * ("<key>_ticks"), or as {"amount": N, "unit": "seconds"} objects.
     */
    private static long durationTicks(JsonObject obj, String... keys) {
        for (String key : keys) {
            if (has(obj, key + "_ticks")) {
                return obj.get(key + "_ticks").getAsLong();
            }
            if (has(obj, key)) {
                JsonElement element = obj.get(key);
                if (element.isJsonPrimitive() && element.getAsJsonPrimitive().isNumber()) {
                    return element.getAsLong();
                }
                if (element.isJsonObject()) {
                    JsonObject duration = element.getAsJsonObject();
                    long amount = has(duration, "amount")
                            ? duration.get("amount").getAsLong()
                            : has(duration, "value") ? duration.get("value").getAsLong() : 0;
                    String unit = has(duration, "unit")
                            ? duration.get("unit").getAsString().toLowerCase() : "ticks";
                    return switch (unit) {
                        case "second", "seconds" -> amount * 20;
                        case "minute", "minutes" -> amount * 20 * 60;
                        case "millisecond", "milliseconds", "ms" ->
                                Math.max(1, amount / 50);
                        default -> amount; // ticks
                    };
                }
            }
        }
        return 0;
    }

    private static Expression buildExpression(JsonObject obj) {
        Expression expression = buildExpressionNode(obj);
        applyPosition(expression, obj);
        return expression;
    }

    private static Expression buildExpressionNode(JsonObject obj) {
        String kind = obj.get("kind").getAsString();
        switch (kind) {
            case "string":
                return new StringLiteral(obj.get("value").getAsString());
            case "number":
                return new NumberLiteral(obj.get("value").getAsDouble(),
                        obj.get("integer").getAsBoolean());
            case "boolean":
                return new BooleanLiteral(obj.get("value").getAsBoolean());
            case "none":
                return new NoneLiteral();
            case "list":
                return new ListLiteral(buildExpressionList(obj.getAsJsonArray("items")));
            case "var":
                return new VariableReference(obj.get("name").getAsString());
            case "prop":
                return new PropertyAccessExpression(buildExpression(obj.getAsJsonObject("target")),
                        obj.get("name").getAsString());
            case "persist_get":
                return new PersistGetExpression(obj.get("name").getAsString(),
                        has(obj, "subject") ? buildExpression(obj.getAsJsonObject("subject")) : null);
            case "type":
                return new TypeLiteral(obj.get("name").getAsString());
            case "binary":
                return new BinaryExpression(buildExpression(obj.getAsJsonObject("left")),
                        BinaryExpression.Operator.valueOf(obj.get("op").getAsString()),
                        buildExpression(obj.getAsJsonObject("right")));
            case "unary":
                return new UnaryExpression(UnaryExpression.Op.valueOf(obj.get("op").getAsString()),
                        buildExpression(obj.getAsJsonObject("operand")));
            case "call":
                return new FunctionCallExpression(obj.get("name").getAsString(),
                        buildExpressionList(obj.getAsJsonArray("args")));
            case "method_call":
                // <receiver>.<name>(<args>) pure collection/string method
                return new net.swofty.nativebridge.execution.expressions.MethodCallExpression(
                        buildExpression(obj.getAsJsonObject("receiver")),
                        obj.get("name").getAsString(),
                        buildExpressionList(obj.getAsJsonArray("args")));
            case "index":
                // target[key] read (map_get / list index) - design phase-10 §1
                return new IndexExpression(
                        buildExpression(obj.getAsJsonObject("target")),
                        buildExpression(obj.getAsJsonObject("key")));
            case "lambda": {
                boolean async = optBoolean(obj, "async");
                return new LambdaExpression(buildParams(obj),
                        buildStatements(obj.getAsJsonArray("body"), async), async);
            }
            case "all_players":
                return new AllPlayersExpression();
            case "viewers_of":
                // viewers of <entity> -> ordered list<Player> (W-viewers)
                return new net.swofty.nativebridge.execution.expressions
                        .ViewersOfExpression(buildExpression(obj.getAsJsonObject("entity")));
            case "schedule": {
                // schedule [after d] [every d] { body } (design 6D)
                JsonArray body = has(obj, "body") ? obj.getAsJsonArray("body")
                        : obj.getAsJsonArray("statements");
                return new net.swofty.nativebridge.execution.expressions.ScheduleExpression(
                        durationTicks(obj, "after", "delay"),
                        durationTicks(obj, "every", "interval"),
                        buildStatements(body, true),
                        optString(obj, "name"));
            }
            case "task_running":
                // <obj>.tasks.<id> is running -> Boolean (W-tasks)
                return new net.swofty.nativebridge.execution.expressions
                        .TaskRunningExpression(
                        buildExpression(obj.getAsJsonObject("owner")),
                        obj.get("id").getAsString());
            case "loader_storage":
                // polar_storage_loader(<backend config>) (design 6B)
                return new net.swofty.nativebridge.execution.expressions
                        .LoaderStorageExpression(
                        buildStorageBackend(obj.getAsJsonObject("backend")));
            case "map_lit": {
                // { "key": expr, ... } script-level map<V> literal (design
                // phase-10 §1). Insertion order is preserved; each entry's
                // value is a full expression node. Evaluates to a MapValue.
                Map<Object, Expression> entries = new LinkedHashMap<>();
                for (JsonElement element : obj.getAsJsonArray("entries")) {
                    JsonObject pair = element.getAsJsonObject();
                    // An Integer-keyed literal emits its keys as JSON numbers;
                    // box them as Integer so they match the Integer keys the
                    // mutating builtins produce (Values.coerceMapKey). String
                    // keys stay Strings.
                    JsonElement keyEl = pair.get("key");
                    Object key = keyEl.getAsJsonPrimitive().isNumber()
                            ? Integer.valueOf(keyEl.getAsInt())
                            : keyEl.getAsString();
                    entries.put(key, buildExpression(pair.getAsJsonObject("value")));
                }
                return new ObjectLiteralExpression(entries);
            }
            case "struct_new": {
                // Guild { name: "...", ... } struct construction (§1.2). Fields
                // are an ordered [{name, value}] list; the runtime fills any
                // omitted defaulted field from the struct declaration.
                List<net.swofty.nativebridge.execution.expressions
                        .StructConstructionExpression.FieldInit> inits = new ArrayList<>();
                for (JsonElement element : obj.getAsJsonArray("fields")) {
                    JsonObject field = element.getAsJsonObject();
                    inits.add(new net.swofty.nativebridge.execution.expressions
                            .StructConstructionExpression.FieldInit(
                            field.get("name").getAsString(),
                            buildExpression(field.getAsJsonObject("value"))));
                }
                return new net.swofty.nativebridge.execution.expressions
                        .StructConstructionExpression(obj.get("struct").getAsString(), inits);
            }
            case "map":
                // { key: expr, ... } nested object (send packet payloads)
                return new ObjectLiteralExpression(buildFieldMap(obj.get("entries")));
            case "object":
                return new ObjectLiteralExpression(buildFieldMap(obj.get("fields")));
            default:
                throw new IllegalArgumentException("Unknown expression kind: " + kind);
        }
    }

    private static NametagRuntime.Part nametagPart(String part) {
        return switch (part.toLowerCase()) {
            case "prefix" -> NametagRuntime.Part.PREFIX;
            case "suffix" -> NametagRuntime.Part.SUFFIX;
            case "color" -> NametagRuntime.Part.COLOR;
            default -> NametagRuntime.Part.TEXT;
        };
    }

    /** Item/mob ids may be literal strings or dynamic expressions. */
    private static Expression buildStringOrExpression(JsonElement element) {
        if (element.isJsonObject()) {
            return buildExpression(element.getAsJsonObject());
        }
        return new StringLiteral(element.getAsString());
    }

    /**
     * Packet field payload: {"field": expr-or-nested-object, ...} or a
     * [{"name":..., "value":...}] list. Nested objects without a "kind"
     * become object literals recursively (design 5D nested records).
     */
    private static Map<String, Expression> buildFieldMap(JsonElement element) {
        Map<String, Expression> fields = new LinkedHashMap<>();
        if (element == null || element.isJsonNull()) {
            return fields;
        }
        if (element.isJsonArray()) {
            for (JsonElement entry : element.getAsJsonArray()) {
                JsonObject pair = entry.getAsJsonObject();
                fields.put(pair.get("name").getAsString(),
                        buildFieldValue(pair.get("value")));
            }
            return fields;
        }
        for (Map.Entry<String, JsonElement> entry : element.getAsJsonObject().entrySet()) {
            fields.put(entry.getKey(), buildFieldValue(entry.getValue()));
        }
        return fields;
    }

    private static Expression buildFieldValue(JsonElement element) {
        if (element.isJsonObject()) {
            JsonObject obj = element.getAsJsonObject();
            if (obj.has("kind")) {
                return buildExpression(obj);
            }
            return new ObjectLiteralExpression(buildFieldMap(obj));
        }
        if (element.isJsonArray()) {
            List<Expression> items = new ArrayList<>();
            for (JsonElement item : element.getAsJsonArray()) {
                items.add(buildFieldValue(item));
            }
            return new ListLiteral(items);
        }
        var primitive = element.getAsJsonPrimitive();
        if (primitive.isBoolean()) {
            return new BooleanLiteral(primitive.getAsBoolean());
        }
        if (primitive.isNumber()) {
            double value = primitive.getAsDouble();
            return new NumberLiteral(value, !primitive.getAsString().contains("."));
        }
        return new StringLiteral(primitive.getAsString());
    }

    private static List<Expression> buildExpressionList(JsonArray array) {
        List<Expression> expressions = new ArrayList<>();
        for (JsonElement element : array) {
            expressions.add(buildExpression(element.getAsJsonObject()));
        }
        return expressions;
    }

    /**
     * "init" (also accepted: "state"/"with") object of an open_gui or
     * replace_gui statement
     */
    private static Map<String, Expression> buildExpressionMap(JsonObject obj) {
        JsonObject source = has(obj, "init") ? obj.getAsJsonObject("init")
                : has(obj, "state") ? obj.getAsJsonObject("state")
                : has(obj, "with") ? obj.getAsJsonObject("with") : null;
        Map<String, Expression> map = new LinkedHashMap<>();
        if (source != null) {
            for (Map.Entry<String, JsonElement> entry : source.entrySet()) {
                map.put(entry.getKey(), buildExpression(entry.getValue().getAsJsonObject()));
            }
        }
        return map;
    }

    private static GuiModel buildGui(JsonObject obj) {
        Map<String, Expression> state = new LinkedHashMap<>();
        if (has(obj, "state")) {
            for (Map.Entry<String, JsonElement> entry : obj.getAsJsonObject("state").entrySet()) {
                state.put(entry.getKey(), buildExpression(entry.getValue().getAsJsonObject()));
            }
        }

        List<GuiSlotModel> slots = new ArrayList<>();
        for (JsonElement element : optArray(obj, "slots")) {
            JsonObject slot = element.getAsJsonObject();
            List<GuiClickHandlerModel> handlers = new ArrayList<>();
            for (JsonElement handlerElement : optArray(slot, "click_handlers")) {
                JsonObject handler = handlerElement.getAsJsonObject();
                handlers.add(new GuiClickHandlerModel(handler.get("filter").getAsString(),
                        buildExecuteBlock(handler.get("body"))));
            }
            slots.add(new GuiSlotModel(intList(slot.getAsJsonArray("slots")),
                    buildItemSpec(slot.getAsJsonObject("item")),
                    handlers, optInt(slot, "refresh")));
        }

        List<GuiEditableModel> editable = new ArrayList<>();
        for (JsonElement element : optArray(obj, "editable")) {
            JsonObject region = element.getAsJsonObject();
            editable.add(new GuiEditableModel(intList(region.getAsJsonArray("slots")),
                    has(region, "on_change") ? buildExecuteBlock(region.get("on_change")) : null));
        }

        GuiPaginateModel paginate = null;
        if (has(obj, "paginate")) {
            JsonObject page = obj.getAsJsonObject("paginate");
            paginate = new GuiPaginateModel(buildExpression(page.getAsJsonObject("source")),
                    intList(page.getAsJsonArray("slots")),
                    buildItemSpec(page.getAsJsonObject("render")),
                    has(page, "on_click") ? buildExecuteBlock(page.get("on_click")) : null,
                    has(page, "prev_slot") ? page.get("prev_slot").getAsInt() : -1,
                    has(page, "next_slot") ? page.get("next_slot").getAsInt() : -1);
        }

        return new GuiModel(obj.get("name").getAsString(),
                obj.get("rows").getAsInt(),
                buildExpression(obj.getAsJsonObject("title")),
                state,
                has(obj, "fill") ? buildGuiItemValue(obj.getAsJsonObject("fill")) : null,
                has(obj, "border") ? buildGuiItemValue(obj.getAsJsonObject("border")) : null,
                slots, editable, paginate,
                optInt(obj, "refresh"),
                has(obj, "on_open") ? buildExecuteBlock(obj.get("on_open")) : null,
                has(obj, "on_close") ? buildExecuteBlock(obj.get("on_close")) : null,
                has(obj, "on_click_fallback") ? buildExecuteBlock(obj.get("on_click_fallback")) : null);
    }

    /**
     * gui fill/border carry either a plain expression (has "kind") or a
     * lowered named-argument ItemSpec object (no "kind")
     */
    private static Expression buildGuiItemValue(JsonObject obj) {
        if (obj.has("kind")) {
            return buildExpression(obj);
        }
        return new ItemSpecExpression(buildItemSpec(obj));
    }

    private static ItemSpecModel buildItemSpec(JsonObject obj) {
        List<Expression> lore = null;
        if (has(obj, "lore")) {
            lore = buildExpressionList(obj.getAsJsonArray("lore"));
        }
        return new ItemSpecModel(
                has(obj, "material") ? buildExpression(obj.getAsJsonObject("material")) : null,
                has(obj, "skull") ? buildExpression(obj.getAsJsonObject("skull")) : null,
                has(obj, "name") ? buildExpression(obj.getAsJsonObject("name")) : null,
                lore,
                has(obj, "amount") ? buildExpression(obj.getAsJsonObject("amount")) : null,
                has(obj, "glint") ? buildExpression(obj.getAsJsonObject("glint")) : null);
    }

    private static ScoreboardModel buildScoreboard(JsonObject obj) {
        return new ScoreboardModel(obj.get("name").getAsString(),
                buildExpression(obj.getAsJsonObject("title")),
                buildUpdate(obj.getAsJsonObject("update")),
                !"shown".equals(optString(obj, "numbers")),
                buildExecuteBlock(obj.get("lines")));
    }

    private static TablistModel buildTablist(JsonObject obj) {
        List<TablistColumnModel> columns = new ArrayList<>();
        for (JsonElement element : optArray(obj, "columns")) {
            columns.add(new TablistColumnModel(
                    buildExecuteBlock(element.getAsJsonObject().get("body"))));
        }
        return new TablistModel(obj.get("name").getAsString(),
                buildUpdate(obj.getAsJsonObject("update")),
                has(obj, "header") ? buildExpression(obj.getAsJsonObject("header")) : null,
                has(obj, "footer") ? buildExpression(obj.getAsJsonObject("footer")) : null,
                columns);
    }

    private static BossbarModel buildBossbar(JsonObject obj) {
        return new BossbarModel(obj.get("name").getAsString(),
                buildExpression(obj.getAsJsonObject("text")),
                buildExpression(obj.getAsJsonObject("progress")),
                obj.get("color").getAsString(),
                obj.get("style").getAsString(),
                buildUpdate(obj.getAsJsonObject("update")));
    }

    private static HologramModel buildHologram(JsonObject obj) {
        return new HologramModel(obj.get("name").getAsString(),
                buildExpression(obj.getAsJsonObject("location")),
                optString(obj, "billboard"),
                has(obj, "scale") ? buildExpression(obj.getAsJsonObject("scale")) : null,
                buildUpdate(obj.getAsJsonObject("update")),
                optBoolean(obj, "per_viewer"),
                buildExecuteBlock(obj.get("lines")),
                buildInlineHandlers(obj));
    }

    private static NpcModel buildNpc(JsonObject obj) {
        return new NpcModel(obj.get("name").getAsString(),
                buildExpression(obj.getAsJsonObject("location")),
                has(obj, "display_name") ? buildExpression(obj.getAsJsonObject("display_name")) : null,
                has(obj, "skin") ? buildNpcSkin(obj.getAsJsonObject("skin")) : null,
                optBoolean(obj, "look_at_players"),
                buildNpcHandler(obj, "on_click"),
                buildNpcHandler(obj, "on_left_click"),
                buildInlineHandlers(obj),
                !has(obj, "viewable") || obj.get("viewable").getAsBoolean());
    }

    /**
     * npc {@code on_click}/{@code on_left_click} handler body. The emitter
     * writes {@code {param, body}}; the {@code player} binder is fixed by the
     * runtime (which binds {@code player} to the clicker), so only the body is
     * lowered here.
     */
    private static ExecuteBlock buildNpcHandler(JsonObject obj, String key) {
        if (!has(obj, key)) {
            return null;
        }
        JsonObject handler = obj.getAsJsonObject(key);
        return buildExecuteBlock(handler.get("body"));
    }

    /** npc skin spec: {@code {kind:"username", username}} or {@code {kind:"texture", texture, signature}}. */
    private static NpcSkinModel buildNpcSkin(JsonObject obj) {
        String kind = obj.get("kind").getAsString();
        if ("texture".equals(kind)) {
            return NpcSkinModel.texture(buildExpression(obj.getAsJsonObject("texture")),
                    has(obj, "signature") ? buildExpression(obj.getAsJsonObject("signature")) : null);
        }
        return NpcSkinModel.username(buildExpression(obj.getAsJsonObject("username")));
    }

    private static ServerConfigModel buildServer(JsonObject obj) {
        JsonObject auth = has(obj, "auth") ? obj.getAsJsonObject("auth") : null;

        // http { port, bind } sub-block (design 6B)
        int httpPort = -1;
        String httpBind = "127.0.0.1";
        if (has(obj, "http")) {
            JsonObject http = obj.getAsJsonObject("http");
            httpPort = has(http, "port") ? http.get("port").getAsInt() : 8080;
            if (has(http, "bind")) {
                httpBind = http.get("bind").getAsString();
            }
        }

        // permissions { "user": ["perm", ...] } (design 6D)
        Map<String, List<String>> permissions = null;
        if (has(obj, "permissions")) {
            permissions = new LinkedHashMap<>();
            for (Map.Entry<String, JsonElement> entry
                    : obj.getAsJsonObject("permissions").entrySet()) {
                List<String> nodes = new ArrayList<>();
                for (JsonElement node : entry.getValue().getAsJsonArray()) {
                    nodes.add(node.isJsonPrimitive() ? node.getAsString()
                            : String.valueOf(scalarValue(node)));
                }
                permissions.put(entry.getKey(), nodes);
            }
        }

        // fishing { min_bite, max_bite } bite-window bounds (phase 8);
        // durations arrive as ticks or {amount, unit} objects
        int fishingMinBite = ServerConfigModel.DEFAULT_FISHING_MIN_BITE_TICKS;
        int fishingMaxBite = ServerConfigModel.DEFAULT_FISHING_MAX_BITE_TICKS;
        if (has(obj, "fishing")) {
            JsonObject fishing = obj.getAsJsonObject("fishing");
            long min = durationTicks(fishing, "min_bite", "min");
            long max = durationTicks(fishing, "max_bite", "max");
            if (min > 0) {
                fishingMinBite = (int) min;
            }
            if (max > 0) {
                fishingMaxBite = (int) max;
            }
        }

        // lighting toggle (default on): plain chunks when explicitly false
        boolean lighting = has(obj, "lighting")
                ? obj.get("lighting").getAsBoolean()
                : ServerConfigModel.DEFAULT_LIGHTING;

        return new ServerConfigModel(
                auth != null ? auth.get("kind").getAsString() : "offline",
                auth != null ? optString(auth, "secret") : null,
                has(obj, "host") ? obj.get("host").getAsString() : "0.0.0.0",
                has(obj, "port") ? obj.get("port").getAsInt() : 25565,
                optString(obj, "brand"),
                optString(obj, "motd"),
                optString(obj, "favicon"),
                httpPort,
                httpBind,
                permissions,
                optBoolean(obj, "open_to_lan"),
                fishingMinBite,
                fishingMaxBite,
                lighting);
    }

    /**
     * storage block: {"backend":{"kind":..., ...fields}, "flush_ticks":int};
     * field names are accepted with a couple of aliases for robustness
     */
    private static StorageConfigModel buildStorage(JsonObject obj) {
        StorageBackendModel backend = buildStorageBackend(obj.getAsJsonObject("backend"));
        int flushTicks = has(obj, "flush_ticks")
                ? obj.get("flush_ticks").getAsInt() : StorageConfigModel.DEFAULT_FLUSH_TICKS;
        return new StorageConfigModel(backend, flushTicks);
    }

    /** Shared by storage{} blocks and loader_storage expressions (6B). */
    private static StorageBackendModel buildStorageBackend(JsonObject backendObj) {
        return new StorageBackendModel(
                backendObj.get("kind").getAsString(),
                firstString(backendObj, "path", "dir", "file"),
                optString(backendObj, "host"),
                has(backendObj, "port") ? backendObj.get("port").getAsInt() : 0,
                optString(backendObj, "database"),
                optString(backendObj, "user"),
                optString(backendObj, "password"),
                firstString(backendObj, "uri", "url", "connection"));
    }

    private static net.swofty.model.StructDefModel buildStructDef(JsonObject obj) {
        List<net.swofty.model.StructFieldModel> fields = new ArrayList<>();
        for (JsonElement element : optArray(obj, "fields")) {
            JsonObject field = element.getAsJsonObject();
            fields.add(new net.swofty.model.StructFieldModel(
                    field.get("name").getAsString(),
                    buildDataType(field.getAsJsonObject("type")),
                    has(field, "default") && field.get("default").isJsonObject()
                            ? buildExpression(field.getAsJsonObject("default")) : null,
                    has(field, "reactive") && field.get("reactive").getAsBoolean(),
                    has(field, "line") ? field.get("line").getAsInt() : -1,
                    has(field, "col") ? field.get("col").getAsInt() : -1));
        }
        return new net.swofty.model.StructDefModel(
                obj.get("name").getAsString(),
                fields,
                has(obj, "line") ? obj.get("line").getAsInt() : -1,
                has(obj, "col") ? obj.get("col").getAsInt() : -1);
    }

    private static PersistentDeclModel buildPersistent(JsonObject obj) {
        return new PersistentDeclModel(
                obj.get("name").getAsString(),
                has(obj, "subject") ? buildDataType(obj.getAsJsonObject("subject")) : null,
                buildDataType(obj.getAsJsonObject("type")),
                buildExpression(obj.getAsJsonObject("default")),
                has(obj, "line") ? obj.get("line").getAsInt() : -1,
                has(obj, "col") ? obj.get("col").getAsInt() : -1);
    }

    private static String firstString(JsonObject obj, String... keys) {
        for (String key : keys) {
            String value = optString(obj, key);
            if (value != null) {
                return value;
            }
        }
        return null;
    }

    private static UpdateCadence buildUpdate(JsonObject obj) {
        if ("manual".equals(obj.get("kind").getAsString())) {
            return UpdateCadence.manual();
        }
        return UpdateCadence.everyTicks(obj.get("value").getAsInt());
    }

    private static SkinSpecModel buildSkin(JsonObject obj) {
        String kind = obj.get("kind").getAsString();
        switch (kind) {
            case "builtin":
                return SkinSpecModel.builtin(obj.get("name").getAsString());
            case "player":
                return SkinSpecModel.player(buildExpression(obj.getAsJsonObject("expr")));
            case "custom":
                return SkinSpecModel.custom(buildExpression(obj.getAsJsonObject("texture")),
                        buildExpression(obj.getAsJsonObject("signature")));
            default:
                throw new IllegalArgumentException("Unknown skin kind: " + kind);
        }
    }

    private static List<Integer> intList(JsonArray array) {
        List<Integer> values = new ArrayList<>();
        for (JsonElement element : array) {
            values.add(element.getAsInt());
        }
        return values;
    }

    private static void applyPosition(Object node, JsonObject obj) {
        if (node instanceof AbstractAstNode astNode) {
            astNode.setSourcePosition(
                    has(obj, "line") ? obj.get("line").getAsInt() : -1,
                    has(obj, "col") ? obj.get("col").getAsInt() : -1);
        }
    }

    private static boolean has(JsonObject obj, String key) {
        return obj.has(key) && !obj.get(key).isJsonNull();
    }

    private static boolean optBoolean(JsonObject obj, String key) {
        return has(obj, key) && obj.get(key).getAsBoolean();
    }

    private static Integer optInt(JsonObject obj, String key) {
        return has(obj, key) ? obj.get(key).getAsInt() : null;
    }

    private static String optString(JsonObject obj, String key) {
        return has(obj, key) ? obj.get(key).getAsString() : null;
    }

    private static JsonArray optArray(JsonObject obj, String key) {
        return has(obj, key) ? obj.getAsJsonArray(key) : new JsonArray();
    }
}
