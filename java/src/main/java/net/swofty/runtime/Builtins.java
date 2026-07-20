package net.swofty.runtime;

import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;
import java.util.function.BiFunction;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.coordinate.Vec;
import net.minestom.server.entity.Player;
import net.minestom.server.instance.Instance;
import net.minestom.server.item.ItemStack;
import net.minestom.server.item.Material;
import net.swofty.InstanceRegistry;
import net.swofty.ScriptError;
import net.swofty.gui.GuiRuntime;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.props.Coercions;
import net.swofty.props.NoneValue;

/**
 * Builtin function table; user-defined functions shadow these by name in
 * ExecutionContext.callFunction.
 */
public final class Builtins {
    private Builtins() {
    }

    /**
     * Call a builtin function
     */
    static Object call(ExecutionContext context, String name, List<Expression> args) {
        switch (name) {
            case "random": {
                Number min = evaluateNumberArg(context, name, args, 0);
                Number max = evaluateNumberArg(context, name, args, 1);
                if (min == null || max == null) {
                    return null;
                }
                int lo = min.intValue();
                int hi = max.intValue();
                if (hi < lo) {
                    int tmp = lo;
                    lo = hi;
                    hi = tmp;
                }
                return ThreadLocalRandom.current().nextInt(lo, hi + 1);
            }
            case "round": {
                Number value = evaluateNumberArg(context, name, args, 0);
                return value != null ? (int) Math.round(value.doubleValue()) : null;
            }
            case "floor": {
                Number value = evaluateNumberArg(context, name, args, 0);
                return value != null ? (int) Math.floor(value.doubleValue()) : null;
            }
            case "ceil": {
                Number value = evaluateNumberArg(context, name, args, 0);
                return value != null ? (int) Math.ceil(value.doubleValue()) : null;
            }
            case "abs": {
                Object value = evaluateArg(context, args, 0);
                if (value instanceof Integer) {
                    return Math.abs((Integer) value);
                }
                if (value instanceof Number) {
                    return Math.abs(((Number) value).doubleValue());
                }
                System.err.println("Error: abs() expects a number argument, got: " + value);
                return null;
            }
            case "uppercase":
                return Values.displayString(evaluateArg(context, args, 0)).toUpperCase();
            case "lowercase":
                return Values.displayString(evaluateArg(context, args, 0)).toLowerCase();
            case "length": {
                Object value = evaluateArg(context, args, 0);
                if (value instanceof String) {
                    return ((String) value).length();
                }
                if (value instanceof Collection) {
                    return ((Collection<?>) value).size();
                }
                System.err.println("Error: length() expects a string or collection, got: " + value);
                return null;
            }
            case "location": {
                double x = requireNumberArg(context, name, args, 0).doubleValue();
                double y = requireNumberArg(context, name, args, 1).doubleValue();
                double z = requireNumberArg(context, name, args, 2).doubleValue();
                if (args.size() >= 5) {
                    float yaw = requireNumberArg(context, name, args, 3).floatValue();
                    float pitch = Math.clamp(
                            requireNumberArg(context, name, args, 4).floatValue(), -90f, 90f);
                    return new Pos(x, y, z, yaw, pitch);
                }
                return new Pos(x, y, z);
            }
            case "item": {
                Material material = Coercions.toMaterial(evaluateArg(context, args, 0));
                if (args.size() >= 2) {
                    int amount = (Integer) Coercions.toItemAmount(evaluateArg(context, args, 1));
                    return ItemStack.of(material, amount);
                }
                return ItemStack.of(material);
            }
            case "player": {
                Object playerName = Coercions.toStringValue(evaluateArg(context, args, 0));
                try {
                    Player player = MinecraftServer.getConnectionManager()
                            .getOnlinePlayerByUsername((String) playerName);
                    return player != null ? player : NoneValue.INSTANCE;
                } catch (Throwable t) {
                    return NoneValue.INSTANCE;
                }
            }
            case "all_players":
                return MinecraftServer.getConnectionManager().getOnlinePlayers();
            case "viewers_of_npc": {
                // viewers of npc "name" -> ordered list<Player> (W-viewers §2).
                // Npcs are name-keyed (declared, not spawn handles), so this
                // resolves the npc's fake-player entity and returns its viewers.
                Object npcName = Coercions.toStringValue(evaluateArg(context, args, 0));
                return net.swofty.npcs.NpcRuntime.viewersOf((String) npcName);
            }
            case "world": {
                Object worldName = Coercions.toStringValue(evaluateArg(context, args, 0));
                Instance instance = InstanceRegistry.get((String) worldName);
                return instance != null ? instance : NoneValue.INSTANCE;
            }
            case "centered": {
                String text = (String) Coercions.toStringValue(evaluateArg(context, args, 0));
                if (text.length() >= 30) {
                    return text.substring(0, 30);
                }
                return " ".repeat((30 - text.length()) / 2) + text;
            }
            case "prompt_input": {
                Player player = context.requirePlayer(
                        evaluateArg(context, args, 0), "prompt_input");
                String placeholder = (String) Coercions.toStringValue(
                        evaluateArg(context, args, 1));
                return GuiRuntime.promptInput(player, placeholder);
            }
            case "min": {
                Object a = evaluateArg(context, args, 0);
                Object b = evaluateArg(context, args, 1);
                return minMax(name, a, b, true);
            }
            case "max": {
                Object a = evaluateArg(context, args, 0);
                Object b = evaluateArg(context, args, 1);
                return minMax(name, a, b, false);
            }
            case "clamp": {
                Number x = requireNumberArg(context, name, args, 0);
                Number lo = requireNumberArg(context, name, args, 1);
                Number hi = requireNumberArg(context, name, args, 2);
                // Math.clamp throws a raw IllegalArgumentException when lo > hi;
                // surface it as a clean, script-level diagnostic instead.
                if (lo.doubleValue() > hi.doubleValue()) {
                    throw new ScriptError("clamp() lower bound " + Values.displayString(lo)
                            + " is greater than upper bound " + Values.displayString(hi));
                }
                if (x instanceof Integer && lo instanceof Integer && hi instanceof Integer) {
                    return Math.clamp(x.intValue(), lo.intValue(), hi.intValue());
                }
                return Math.clamp(x.doubleValue(), lo.doubleValue(), hi.doubleValue());
            }
            case "format_number": {
                Number value = requireNumberArg(context, name, args, 0);
                if (value instanceof Integer || value instanceof Long) {
                    return NumberFormat.getIntegerInstance(Locale.US).format(value.longValue());
                }
                return NumberFormat.getInstance(Locale.US).format(value.doubleValue());
            }
            case "custom_item": {
                String id = (String) Coercions.toStringValue(evaluateArg(context, args, 0));
                int amount = args.size() >= 2
                        ? requireNumberArg(context, name, args, 1).intValue() : 1;
                return net.swofty.items.ItemRegistry.build(id, amount);
            }
            case "custom_id": {
                Object value = evaluateArg(context, args, 0);
                if (!(value instanceof ItemStack stack)) {
                    return NoneValue.INSTANCE;
                }
                String id = net.swofty.items.ItemRegistry.customId(stack);
                return id != null ? id : NoneValue.INSTANCE;
            }
            case "all_mobs": {
                String id = args.isEmpty() ? null
                        : (String) Coercions.toStringValue(evaluateArg(context, args, 0));
                return net.swofty.mobs.MobRegistry.all(id);
            }
            case "entity_id_of": {
                Object value = evaluateArg(context, args, 0);
                if (value instanceof net.minestom.server.entity.Entity entity) {
                    return entity.getEntityId();
                }
                if (value instanceof net.swofty.displays.SwoftDisplay display) {
                    return display.entity().getEntityId();
                }
                throw new ScriptError("entity_id_of() expects an entity, got: "
                        + Values.displayString(value));
            }

            // ---------- phase-6: display entities (design 6B) ----------
            // signature: (content, location) - checker-enforced; the
            // swapped order is tolerated at runtime for robustness
            case "spawn_text_display":
            case "spawn_item_display":
            case "spawn_block_display": {
                Object first = evaluateArg(context, args, 0);
                Object second = evaluateArg(context, args, 1);
                Object content = first instanceof Pos ? second : first;
                Object where = first instanceof Pos ? first : second;
                if (!(where instanceof Pos pos)) {
                    throw new ScriptError(name + "() expects (content, location), got: "
                            + Values.displayString(first) + ", "
                            + Values.displayString(second));
                }
                net.swofty.displays.SwoftDisplay.Kind kind = switch (name) {
                    case "spawn_item_display" -> net.swofty.displays.SwoftDisplay.Kind.ITEM;
                    case "spawn_block_display" -> net.swofty.displays.SwoftDisplay.Kind.BLOCK;
                    default -> net.swofty.displays.SwoftDisplay.Kind.TEXT;
                };
                var display = new net.swofty.displays.SwoftDisplay(kind);
                if (content != null && !NoneValue.isNone(content)) {
                    switch (kind) {
                        case TEXT -> display.setText(
                                (String) Coercions.toStringValue(content));
                        case ITEM -> display.setItem(content instanceof ItemStack stack
                                ? stack
                                : ItemStack.of(Coercions.toMaterial(content)));
                        case BLOCK -> display.setBlock(
                                (String) Coercions.toStringValue(content));
                    }
                }
                Instance instance = context.getSender() instanceof Player player
                        && player.getInstance() != null
                        ? player.getInstance()
                        : InstanceRegistry.get("world");
                if (instance == null) {
                    throw new ScriptError(name + "(): no world to spawn into");
                }
                display.spawn(instance, pos);
                return display;
            }

            // ---------- phase-6: songs (design 6B) ----------
            case "song": {
                String songName = (String) Coercions.toStringValue(
                        evaluateArg(context, args, 0));
                return net.swofty.music.SongRegistry.get(songName);
            }

            // ---------- phase-6: skins (design 6D) ----------
            case "skin": {
                String texture = (String) Coercions.toStringValue(
                        evaluateArg(context, args, 0));
                String signature = args.size() >= 2
                        ? (String) Coercions.toStringValue(evaluateArg(context, args, 1))
                        : null;
                return new net.minestom.server.entity.PlayerSkin(texture, signature);
            }
            case "fetch_skin": {
                String username = (String) Coercions.toStringValue(
                        evaluateArg(context, args, 0));
                var skin = net.swofty.skins.SkinFetcher.fetch(username);
                return skin != null ? skin : NoneValue.INSTANCE;
            }

            // ---------- phase-6: map canvases (design 6D) ----------
            case "map_canvas":
                return new net.swofty.maps.MapCanvas();

            // ---------- W-blocks: block value (design §1) ----------
            case "block": {
                String rawId = (String) Coercions.toStringValue(evaluateArg(context, args, 0));
                net.swofty.blocks.BlockValue value = new net.swofty.blocks.BlockValue(
                        net.swofty.nativebridge.execution.commands.blocks.SetBlockStatement
                                .resolveBlock(rawId));
                if (args.size() >= 2) {
                    Object props = evaluateArg(context, args, 1);
                    if (!(props instanceof MapValue map)) {
                        throw new ScriptError("block(): the second argument must be a "
                                + "property map, got: " + Values.displayString(props));
                    }
                    for (Map.Entry<Object, Object> entry : map.entrySet()) {
                        value = value.with(String.valueOf(entry.getKey()),
                                (String) Coercions.toStringValue(entry.getValue()));
                    }
                }
                return value;
            }

            // ---------- phase-6: blocks (design 6D) ----------
            case "block_at": {
                Object where = evaluateArg(context, args, 0);
                if (!(where instanceof Pos pos)) {
                    throw new ScriptError("block_at() expects a location, got: "
                            + Values.displayString(where));
                }
                Instance instance;
                if (args.size() >= 2) {
                    instance = (Instance) Coercions.toInstance(evaluateArg(context, args, 1));
                } else if (context.getSender() instanceof Player player
                        && player.getInstance() != null) {
                    instance = player.getInstance();
                } else {
                    instance = InstanceRegistry.get("world");
                }
                if (instance == null) {
                    throw new ScriptError("block_at(): no world available");
                }
                // Mirror set block's auto-chunk-load semantics: reads pull
                // the chunk in (through the world's chunk loader) instead
                // of failing on a chunk no player has loaded yet
                return net.swofty.async.TickDispatch.call(() -> {
                    net.minestom.server.instance.Chunk chunk =
                            instance.getChunkAt(pos.blockX(), pos.blockZ());
                    if (chunk == null) {
                        chunk = instance.loadOptionalChunk(
                                net.minestom.server.coordinate.CoordConversion
                                        .globalToChunk(pos.blockX()),
                                net.minestom.server.coordinate.CoordConversion
                                        .globalToChunk(pos.blockZ())).join();
                    }
                    if (chunk == null) {
                        throw new ScriptError("block_at(): chunk at "
                                + pos.blockX() + ", " + pos.blockZ()
                                + " is not loaded (auto chunk load is disabled)");
                    }
                    // W-tasks: remember the world + position so
                    // block_at(loc).tasks.<id> keys its task registry by
                    // position and auto-cancels when the block is removed.
                    return new net.swofty.blocks.BlockValue(
                            chunk.getBlock(pos.blockX(), pos.blockY(), pos.blockZ()),
                            instance, pos);
                });
            }

            // ---------- phase-6: tps (design 6B/6D) ----------
            case "tps_string":
                return net.swofty.tps.TpsMonitor.instance().tpsString();
            case "average_tps_string":
                return net.swofty.tps.TpsMonitor.instance().averageTpsString();
            case "tps_at": {
                Number secondsAgo = requireNumberArg(context, name, args, 0);
                return net.swofty.tps.TpsMonitor.instance().tpsAt(secondsAgo.intValue());
            }

            // ---------- phase-6: worlds (design 6B/6D) ----------
            case "anvil_loader": {
                String dir = (String) Coercions.toStringValue(evaluateArg(context, args, 0));
                return new net.swofty.worlds.AnvilWorldLoader(dir);
            }
            case "polar_loader": {
                String dir = (String) Coercions.toStringValue(evaluateArg(context, args, 0));
                return new net.swofty.worlds.PolarFileWorldLoader(dir);
            }
            case "polar_storage_loader": {
                Object config = evaluateArg(context, args, 0);
                return net.swofty.worlds.PolarStorageWorldLoader.of(
                        storageBackendOf(config));
            }
            case "world_exists": {
                String worldName = (String) Coercions.toStringValue(
                        evaluateArg(context, args, 0));
                Object loader = evaluateArg(context, args, 1);
                if (!(loader instanceof net.swofty.worlds.SwoftWorldLoader worldLoader)) {
                    throw new ScriptError("world_exists() expects a world loader second, got: "
                            + Values.displayString(loader));
                }
                return worldLoader.exists(worldName);
            }
            case "all_worlds": {
                Object loader = evaluateArg(context, args, 0);
                if (!(loader instanceof net.swofty.worlds.SwoftWorldLoader worldLoader)) {
                    throw new ScriptError("all_worlds() expects a world loader, got: "
                            + Values.displayString(loader));
                }
                return worldLoader.list();
            }

            // ---------- phase-6: permissions (design 6D) ----------
            case "has_permission": {
                Object subject = evaluateArg(context, args, 0);
                String permission = (String) Coercions.toStringValue(
                        evaluateArg(context, args, 1));
                net.minestom.server.command.CommandSender sender =
                        subject instanceof net.minestom.server.command.CommandSender cs
                                ? cs : context.getSender();
                return net.swofty.permissions.Permissions.check(sender, permission);
            }
            case "uuid_of": {
                Object value = evaluateArg(context, args, 0);
                if (value instanceof net.minestom.server.entity.Entity entity) {
                    return entity.getUuid().toString();
                }
                throw new ScriptError("uuid_of() expects an entity, got: "
                        + Values.displayString(value));
            }

            // ---------- phase-8: offline players ----------
            case "offline_player": {
                // seen-store lookup, case-insensitive; none if never seen
                String playerName = (String) Coercions.toStringValue(
                        evaluateArg(context, args, 0));
                net.swofty.players.OfflinePlayerValue found =
                        net.swofty.players.SeenPlayersStore.byName(playerName);
                return found != null ? found : NoneValue.INSTANCE;
            }
            case "offline_player_uuid": {
                // total: constructs the identity; name from the store else
                // "unknown"
                String uuid = (String) Coercions.toStringValue(
                        evaluateArg(context, args, 0));
                return net.swofty.players.SeenPlayersStore.byUuid(uuid);
            }
            case "fetch_offline_player": {
                // ASYNC-ONLY Mojang username -> uuid; none on failure or
                // timeout; a success also seeds the seen-store
                String playerName = (String) Coercions.toStringValue(
                        evaluateArg(context, args, 0));
                net.swofty.players.OfflinePlayerValue fetched =
                        net.swofty.players.MojangNameResolver.fetch(playerName);
                return fetched != null ? fetched : NoneValue.INSTANCE;
            }
            case "all_seen_players":
                return net.swofty.players.SeenPlayersStore.all();

            // ---------- phase-7: entities ----------
            case "velocity": {
                double x = requireNumberArg(context, name, args, 0).doubleValue();
                double y = requireNumberArg(context, name, args, 1).doubleValue();
                double z = requireNumberArg(context, name, args, 2).doubleValue();
                return new net.minestom.server.coordinate.Vec(x, y, z);
            }
            case "in_front_of": {
                // A Pos <distance> blocks ahead of an entity's eyes along its
                // facing direction: eye position + view unit vector * distance.
                // The returned Pos keeps the entity's yaw/pitch so it can be
                // teleported to / spawned at facing the same way.
                Object first = evaluateArg(context, args, 0);
                if (!(first instanceof net.minestom.server.entity.Entity entity)) {
                    System.err.println("Error: in_front_of() expects an entity, got: " + first);
                    return NoneValue.INSTANCE;
                }
                double distance = requireNumberArg(context, name, args, 1).doubleValue();
                Pos pos = entity.getPosition();
                Pos eye = pos.add(0, entity.getEyeHeight(), 0);
                net.minestom.server.coordinate.Vec direction = pos.direction();
                return eye.add(direction.mul(distance));
            }
            case "all_entities": {
                String type = args.isEmpty() ? null
                        : (String) Coercions.toStringValue(evaluateArg(context, args, 0));
                net.minestom.server.entity.EntityType filter = type == null ? null
                        : net.swofty.mobs.SwoftMob.resolveType(type);
                java.util.List<Object> entities = new java.util.ArrayList<>();
                for (Instance instance : MinecraftServer.getInstanceManager().getInstances()) {
                    for (net.minestom.server.entity.Entity entity : instance.getEntities()) {
                        if (filter == null || entity.getEntityType().equals(filter)) {
                            entities.add(entity);
                        }
                    }
                }
                return entities;
            }
            // ---------- phase-10: map / dictionary (design phase-10 §1) --
            case "new_map":
                return new MapValue();
            case "map_get": {
                MapValue map = requireMap(name, evaluateArg(context, args, 0));
                Object key = mapKey(name, evaluateArg(context, args, 1));
                Object value = map.get(key);
                // absent key -> none, so map_get integrates with
                // exists/otherwise like every other optional-returning builtin
                return value != null ? value : NoneValue.INSTANCE;
            }
            case "map_set": {
                MapValue map = requireMap(name, evaluateArg(context, args, 0));
                Object key = mapKey(name, evaluateArg(context, args, 1));
                Object value = evaluateArg(context, args, 2);
                if (NoneValue.isNone(value)) {
                    // storing none is a delete: keeps map_has/keys/size honest
                    map.remove(key);
                } else {
                    map.put(key, value);
                }
                return map;
            }
            case "map_has": {
                MapValue map = requireMap(name, evaluateArg(context, args, 0));
                Object key = mapKey(name, evaluateArg(context, args, 1));
                return map.containsKey(key);
            }
            case "map_delete": {
                MapValue map = requireMap(name, evaluateArg(context, args, 0));
                Object key = mapKey(name, evaluateArg(context, args, 1));
                map.remove(key);
                return map;
            }
            case "map_keys": {
                MapValue map = requireMap(name, evaluateArg(context, args, 0));
                // a fresh list snapshot (Collection) so loop/length work and
                // mutating the map mid-iteration cannot ConcurrentModify
                return new java.util.ArrayList<Object>(map.keySet());
            }
            case "map_size": {
                MapValue map = requireMap(name, evaluateArg(context, args, 0));
                return map.size();
            }

            // ---------- W-pvp: entity attributes, modifiers, combat effects,
            // and native trackers were free functions. They are REMOVED: the
            // attribute keys are direct rw entity properties, the trackers are
            // ro properties (see PropertyTables.registerCombatSurface), and the
            // effects are English statement verbs (damage/knock/apply/remove/
            // shoot + add/remove modifier, see commands.combat.*). ------------

            // ---------- collections pass: sorting (non-mutating, stable) ----
            case "sort": {
                List<Object> copy = requireListCopy(name, evaluateArg(context, args, 0));
                sortNatural(name, copy, false);
                return copy;
            }
            case "sort_desc": {
                List<Object> copy = requireListCopy(name, evaluateArg(context, args, 0));
                sortNatural(name, copy, true);
                return copy;
            }
            case "sort_by":
            case "sort_by_desc": {
                boolean desc = name.equals("sort_by_desc");
                List<Object> copy = requireListCopy(name, evaluateArg(context, args, 0));
                SwoftCallable key = requireCallable(name, evaluateArg(context, args, 1));
                sortByKey(context, name, copy, key, desc);
                return copy;
            }
            case "reverse": {
                List<Object> copy = requireListCopy(name, evaluateArg(context, args, 0));
                java.util.Collections.reverse(copy);
                return copy;
            }
            case "min_by":
            case "max_by": {
                boolean max = name.equals("max_by");
                List<Object> list = requireListCopy(name, evaluateArg(context, args, 0));
                SwoftCallable key = requireCallable(name, evaluateArg(context, args, 1));
                return extreme(context, name, list, key, max);
            }
            case "sort_by_key":
            case "sort_by_key_desc": {
                MapValue map = requireMap(name, evaluateArg(context, args, 0));
                return sortedMap(name, map, name.endsWith("_desc"),
                        (k, v) -> k, context, null);
            }
            case "sort_by_value":
            case "sort_by_value_desc": {
                MapValue map = requireMap(name, evaluateArg(context, args, 0));
                return sortedMap(name, map, name.endsWith("_desc"),
                        (k, v) -> v, context, null);
            }
            case "sort_map_by":
            case "sort_map_by_desc": {
                MapValue map = requireMap(name, evaluateArg(context, args, 0));
                SwoftCallable key = requireCallable(name, evaluateArg(context, args, 1));
                return sortedMap(name, map, name.endsWith("_desc"), null, context, key);
            }

            // ---------- collections pass: random (ThreadLocalRandom) --------
            case "random_float": {
                double lo = requireNumberArg(context, name, args, 0).doubleValue();
                double hi = requireNumberArg(context, name, args, 1).doubleValue();
                if (hi < lo) {
                    double tmp = lo;
                    lo = hi;
                    hi = tmp;
                }
                // uniform in [lo, hi); a zero-width range yields the bound
                return lo == hi ? lo
                        : ThreadLocalRandom.current().nextDouble(lo, hi);
            }
            case "random_chance": {
                double p = requireNumberArg(context, name, args, 0).doubleValue();
                if (p <= 0) {
                    return false;
                }
                if (p >= 1) {
                    return true;
                }
                return ThreadLocalRandom.current().nextDouble() < p;
            }
            case "random_bool":
                return ThreadLocalRandom.current().nextBoolean();
            case "random_in": {
                List<Object> list = requireListCopy(name, evaluateArg(context, args, 0));
                if (list.isEmpty()) {
                    return NoneValue.INSTANCE;
                }
                return list.get(ThreadLocalRandom.current().nextInt(list.size()));
            }
            case "shuffle": {
                List<Object> copy = requireListCopy(name, evaluateArg(context, args, 0));
                // the copy is a NEW list, so the argument is never mutated
                shuffleInPlace(copy);
                return copy;
            }

            // ---------- scheduler v2: is_running(handle | name) ------------
            case "is_running": {
                Object value = evaluateArg(context, args, 0);
                if (value instanceof net.swofty.sched.ScheduleHandle handle) {
                    return handle.isRunning();
                }
                if (value instanceof String scheduleName) {
                    net.swofty.sched.ScheduleHandle handle =
                            net.swofty.sched.ScheduleRegistry.lookup(scheduleName);
                    return handle != null && handle.isRunning();
                }
                return false;
            }

            // ---------- phase-10: item <-> NBT string (design phase-10 §5) -
            case "to_nbt": {
                Object value = evaluateArg(context, args, 0);
                if (!(value instanceof ItemStack stack)) {
                    throw new ScriptError("to_nbt() expects an item, got: "
                            + Values.displayString(value));
                }
                try {
                    return net.kyori.adventure.nbt.TagStringIO.tagStringIO()
                            .asString(stack.toItemNBT());
                } catch (Exception e) {
                    throw new ScriptError("to_nbt() failed to serialize item: "
                            + e.getMessage());
                }
            }
            case "from_nbt": {
                String snbt = (String) Coercions.toStringValue(
                        evaluateArg(context, args, 0));
                try {
                    net.kyori.adventure.nbt.CompoundBinaryTag compound =
                            net.kyori.adventure.nbt.TagStringIO.tagStringIO().asCompound(snbt);
                    ItemStack restored = ItemStack.fromItemNBT(compound);
                    return restored != null ? restored : NoneValue.INSTANCE;
                } catch (Exception e) {
                    // malformed SNBT / not an item -> none (parse-back is total)
                    return NoneValue.INSTANCE;
                }
            }
            // ---------- W-stdlib B3: math beyond arithmetic (java.lang.Math) --
            case "mod": {
                Number a = requireNumberArg(context, name, args, 0);
                Number b = requireNumberArg(context, name, args, 1);
                if (a instanceof Integer && b instanceof Integer) {
                    int d = b.intValue();
                    if (d == 0) {
                        throw new ScriptError("mod() by zero");
                    }
                    return Math.floorMod(a.intValue(), d);
                }
                double da = a.doubleValue();
                double db = b.doubleValue();
                if (db == 0.0) {
                    throw new ScriptError("mod() by zero");
                }
                double r = da % db;
                // floored modulo: result takes the divisor's sign
                if (r != 0.0 && ((r < 0) != (db < 0))) {
                    r += db;
                }
                return r;
            }
            case "sqrt":
                return Math.sqrt(requireNumberArg(context, name, args, 0).doubleValue());
            case "pow":
                return Math.pow(requireNumberArg(context, name, args, 0).doubleValue(),
                        requireNumberArg(context, name, args, 1).doubleValue());
            case "round_to": {
                double v = requireNumberArg(context, name, args, 0).doubleValue();
                int places = requireNumberArg(context, name, args, 1).intValue();
                double factor = Math.pow(10, places);
                return Math.round(v * factor) / factor;
            }
            case "sin":
                return Math.sin(requireNumberArg(context, name, args, 0).doubleValue());
            case "cos":
                return Math.cos(requireNumberArg(context, name, args, 0).doubleValue());
            case "tan":
                return Math.tan(requireNumberArg(context, name, args, 0).doubleValue());
            case "asin":
                return Math.asin(requireNumberArg(context, name, args, 0).doubleValue());
            case "acos":
                return Math.acos(requireNumberArg(context, name, args, 0).doubleValue());
            case "atan":
                return Math.atan(requireNumberArg(context, name, args, 0).doubleValue());
            case "atan2":
                return Math.atan2(requireNumberArg(context, name, args, 0).doubleValue(),
                        requireNumberArg(context, name, args, 1).doubleValue());
            case "ln":
                return Math.log(requireNumberArg(context, name, args, 0).doubleValue());
            case "log": {
                double x = requireNumberArg(context, name, args, 0).doubleValue();
                if (args.size() >= 2) {
                    // two-arg form: logarithm of x in the given base
                    double base = requireNumberArg(context, name, args, 1).doubleValue();
                    return Math.log(x) / Math.log(base);
                }
                return Math.log(x);
            }
            case "log10":
                return Math.log10(requireNumberArg(context, name, args, 0).doubleValue());
            case "pi":
                return Math.PI;
            case "e":
                return Math.E;
            case "sign":
                return (int) Math.signum(requireNumberArg(context, name, args, 0).doubleValue());
            case "sum":
            case "product": {
                List<Object> list = requireListCopy(name, evaluateArg(context, args, 0));
                boolean product = name.equals("product");
                boolean allInt = true;
                double acc = product ? 1.0 : 0.0;
                long lacc = product ? 1L : 0L;
                for (Object element : list) {
                    if (!(element instanceof Number num)) {
                        throw new ScriptError(name + "() expects a list of numbers, got element: "
                                + Values.displayString(element));
                    }
                    if (!(element instanceof Integer)) {
                        allInt = false;
                    }
                    double d = num.doubleValue();
                    if (product) {
                        acc *= d;
                        lacc *= num.longValue();
                    } else {
                        acc += d;
                        lacc += num.longValue();
                    }
                }
                // Integer list -> Integer result (matches the checker's join)
                return allInt ? (Object) (int) lacc : (Object) acc;
            }

            // ---------- W-stdlib B8: decimal-place number formatting ---------
            case "format_decimals": {
                double v = requireNumberArg(context, name, args, 0).doubleValue();
                int places = Math.max(0, requireNumberArg(context, name, args, 1).intValue());
                return String.format(Locale.US, "%." + places + "f", v);
            }

            // ---------- W-stdlib B4: random (java.util.Random via rng()) ------
            case "random_int": {
                int lo = requireNumberArg(context, name, args, 0).intValue();
                int hi = requireNumberArg(context, name, args, 1).intValue();
                if (hi < lo) {
                    int tmp = lo;
                    lo = hi;
                    hi = tmp;
                }
                // inclusive on both ends
                return lo + rng().nextInt(hi - lo + 1);
            }
            case "random_double": {
                double lo = requireNumberArg(context, name, args, 0).doubleValue();
                double hi = requireNumberArg(context, name, args, 1).doubleValue();
                if (hi < lo) {
                    double tmp = lo;
                    lo = hi;
                    hi = tmp;
                }
                return lo == hi ? lo : lo + rng().nextDouble() * (hi - lo);
            }
            case "chance": {
                double p = requireNumberArg(context, name, args, 0).doubleValue();
                if (p <= 0) {
                    return false;
                }
                if (p >= 1) {
                    return true;
                }
                return rng().nextDouble() < p;
            }
            case "random_element": {
                List<Object> list = requireListCopy(name, evaluateArg(context, args, 0));
                if (list.isEmpty()) {
                    return NoneValue.INSTANCE;
                }
                return list.get(rng().nextInt(list.size()));
            }
            case "random_uuid":
                return java.util.UUID.randomUUID().toString();
            case "random_seed": {
                long seed = requireNumberArg(context, name, args, 0).longValue();
                // installs a per-thread seeded generator; subsequent random_int/
                // random_double/chance/random_element/random_uuid draws are then
                // reproducible on this thread until re-seeded
                SEEDED_RNG.set(new java.util.Random(seed));
                return NoneValue.INSTANCE;
            }

            // ---------- W-stdlib B1: string free helpers --------------------
            case "parse": {
                String source = requireStringArg(context, name, args, 0);
                if (!(args.size() >= 2
                        && args.get(1) instanceof net.swofty.nativebridge.execution
                                .expressions.VariableReference typeRef)) {
                    throw new ScriptError("parse() expects a type name as its second argument");
                }
                return parseAs(source, typeRef.getName());
            }
            case "matches": {
                String source = requireStringArg(context, name, args, 0);
                String regex = requireStringArg(context, name, args, 1);
                try {
                    return source.matches(regex);
                } catch (java.util.regex.PatternSyntaxException e) {
                    return false;
                }
            }
            case "stripped":
            case "strip_color":
                return stripColor(requireStringArg(context, name, args, 0));
            case "formatted":
            case "legacy_to_mini":
                return legacyToMini(requireStringArg(context, name, args, 0));
            case "type_of":
                return typeName(evaluateArg(context, args, 0));

            // ---------- W-stdlib B2: color & format (MiniMessage strings) ----
            case "gradient": {
                String text = requireStringArg(context, name, args, 0);
                String from = normalizeHex(requireStringArg(context, name, args, 1));
                String to = normalizeHex(requireStringArg(context, name, args, 2));
                return "<gradient:#" + from + ":#" + to + ">" + text + "</gradient>";
            }
            case "rainbow":
                return "<rainbow>" + requireStringArg(context, name, args, 0) + "</rainbow>";

            // ---------- W-stdlib B7: location / region / vector math ---------
            case "distance": {
                Pos a = requireLocationArg(context, name, args, 0);
                Pos b = requireLocationArg(context, name, args, 1);
                return a.distance(b);
            }
            case "direction_from": {
                Pos a = requireLocationArg(context, name, args, 0);
                Pos b = requireLocationArg(context, name, args, 1);
                Vec dir = new Vec(b.x() - a.x(), b.y() - a.y(), b.z() - a.z());
                return dir.isZero() ? dir : dir.normalize();
            }
            case "above": {
                Pos loc = requireLocationArg(context, name, args, 0);
                return loc.add(0, requireNumberArg(context, name, args, 1).doubleValue(), 0);
            }
            case "below": {
                Pos loc = requireLocationArg(context, name, args, 0);
                return loc.sub(0, requireNumberArg(context, name, args, 1).doubleValue(), 0);
            }
            case "is_within": {
                Pos p = requireLocationArg(context, name, args, 0);
                Pos c1 = requireLocationArg(context, name, args, 1);
                Pos c2 = requireLocationArg(context, name, args, 2);
                return p.x() >= Math.min(c1.x(), c2.x()) && p.x() <= Math.max(c1.x(), c2.x())
                        && p.y() >= Math.min(c1.y(), c2.y()) && p.y() <= Math.max(c1.y(), c2.y())
                        && p.z() >= Math.min(c1.z(), c2.z()) && p.z() <= Math.max(c1.z(), c2.z());
            }
            case "blocks_in_radius": {
                Pos loc = requireLocationArg(context, name, args, 0);
                int radius = Math.max(0, Math.min(64,
                        requireNumberArg(context, name, args, 1).intValue()));
                long r2 = (long) radius * radius;
                int bx = loc.blockX();
                int by = loc.blockY();
                int bz = loc.blockZ();
                List<Object> out = new java.util.ArrayList<>();
                for (int dx = -radius; dx <= radius; dx++) {
                    for (int dy = -radius; dy <= radius; dy++) {
                        for (int dz = -radius; dz <= radius; dz++) {
                            if ((long) dx * dx + (long) dy * dy + (long) dz * dz <= r2) {
                                out.add(new Pos(bx + dx, by + dy, bz + dz));
                            }
                        }
                    }
                }
                return out;
            }
            case "players_in_radius": {
                Pos loc = requireLocationArg(context, name, args, 0);
                double radius = requireNumberArg(context, name, args, 1).doubleValue();
                double r2 = radius * radius;
                List<Object> out = new java.util.ArrayList<>();
                for (Player player : MinecraftServer.getConnectionManager().getOnlinePlayers()) {
                    if (player.getPosition().distanceSquared(loc) <= r2) {
                        out.add(player);
                    }
                }
                return out;
            }
            case "vec":
                return new Vec(requireNumberArg(context, name, args, 0).doubleValue(),
                        requireNumberArg(context, name, args, 1).doubleValue(),
                        requireNumberArg(context, name, args, 2).doubleValue());
            case "location_of": {
                net.minestom.server.entity.Entity entity =
                        requireEntityArg(context, name, args, 0);
                return entity.getPosition();
            }

            default:
                System.err.println("Error: Unknown function: " + name);
                return null;
        }
    }

    // ==================================================================
    // W-collections: method-call dispatch (receiver.name(args))
    //
    // A second entry point onto the SAME runtime the free builtins use: the
    // sort/random/map-op helpers below (sortNatural, sortByKey, extreme,
    // sortedMap, sortedMap, mapKey, requireCallable, shuffleInPlace) are shared,
    // no logic is duplicated. Dispatch is by the receiver's runtime type;
    // mutating list/map methods mutate the live value in place, pure methods
    // return new values.
    // ==================================================================

    /**
     * Dispatch {@code receiver.name(args)} by the receiver's runtime type.
     * The static checker has already validated that the method exists on the
     * receiver's type and that arity/arg types line up, so these switches only
     * re-check what the runtime needs (a live List for mutation, key coercion).
     */
    static Object callMethod(ExecutionContext context, Object receiver, String name,
            List<Expression> args) {
        if (receiver instanceof MapValue map) {
            return mapMethod(context, map, name, args);
        }
        if (receiver instanceof String str) {
            return stringMethod(context, str, name, args);
        }
        if (receiver instanceof Collection<?>) {
            return listMethod(context, receiver, name, args);
        }
        if (receiver instanceof net.swofty.blocks.BlockValue block) {
            return blockMethod(context, block, name, args);
        }
        throw new ScriptError("cannot call method '" + name + "' on "
                + Values.displayString(receiver));
    }

    // -------------------------- block methods -------------------------

    /**
     * W-blocks method dispatch on a {@link net.swofty.blocks.BlockValue}: the
     * immutable {@code with}/{@code with_nbt}/{@code with_tag} builders plus the
     * {@code property}/{@code get_tag} readers. {@code with} validates the
     * property/value against the block's own state schema (no silent failure).
     */
    private static Object blockMethod(ExecutionContext context,
            net.swofty.blocks.BlockValue block, String name, List<Expression> args) {
        switch (name) {
            case "with":
                return block.with(strArg(context, args, 0), strArg(context, args, 1));
            case "with_nbt":
                return block.withNbt(strArg(context, args, 0));
            case "with_tag":
                return block.withTag(strArg(context, args, 0), strArg(context, args, 1));
            case "property":
                return block.property(strArg(context, args, 0));
            case "get_tag":
                return block.getTag(strArg(context, args, 0));
            default:
                throw new ScriptError("unknown block method '" + name + "'");
        }
    }

    // -------------------------- map methods ---------------------------

    private static Object mapMethod(ExecutionContext context, MapValue map, String name,
            List<Expression> args) {
        switch (name) {
            // ---- pure expression methods ----
            case "get": {
                Object value = map.get(mapKey(name, evaluateArg(context, args, 0)));
                return value != null ? value : NoneValue.INSTANCE;
            }
            case "has":
                return map.containsKey(mapKey(name, evaluateArg(context, args, 0)));
            case "get_or": {
                Object value = map.get(mapKey(name, evaluateArg(context, args, 0)));
                // unwrap_or: present value, else the caller's default
                return value != null ? value : evaluateArg(context, args, 1);
            }
            case "sorted_by_key":
                return sortedMap(name, map, false, (k, v) -> k, context, null);
            case "sorted_by_key_desc":
                return sortedMap(name, map, true, (k, v) -> k, context, null);
            case "sorted_by_value":
                return sortedMap(name, map, false, (k, v) -> v, context, null);
            case "sorted_by_value_desc":
                return sortedMap(name, map, true, (k, v) -> v, context, null);
            case "sorted_by": {
                SwoftCallable key = requireCallable(name, evaluateArg(context, args, 0));
                return sortedMap(name, map, false, null, context, key);
            }
            // ---- mutating statement methods (live map) ----
            case "set": {
                Object key = mapKey(name, evaluateArg(context, args, 0));
                Object value = evaluateArg(context, args, 1);
                // storing none is a delete, matching map_set / index-assign
                if (NoneValue.isNone(value)) {
                    map.remove(key);
                } else {
                    map.put(key, value);
                }
                return map;
            }
            case "delete":
                map.remove(mapKey(name, evaluateArg(context, args, 0)));
                return map;
            case "clear":
                map.clear();
                return map;
            case "put_all": {
                MapValue other = requireMap(name, evaluateArg(context, args, 0));
                // per-entry put() (not putAll) so MapValue's synchronized
                // mutator guards the persistence flush thread
                for (Map.Entry<Object, Object> entry : other.entrySet()) {
                    map.put(entry.getKey(), entry.getValue());
                }
                return map;
            }
            default:
                throw new ScriptError("unknown map method '" + name + "'");
        }
    }

    // -------------------------- list methods --------------------------

    private static Object listMethod(ExecutionContext context, Object receiver, String name,
            List<Expression> args) {
        switch (name) {
            // ---- pure expression methods ----
            case "contains":
                return listIndexOf(readList(name, receiver), evaluateArg(context, args, 0)) >= 0;
            case "index_of": {
                int index = listIndexOf(readList(name, receiver), evaluateArg(context, args, 0));
                return index >= 0 ? (Object) index : NoneValue.INSTANCE;
            }
            case "get": {
                List<Object> list = readList(name, receiver);
                int index = intArg(context, name, args, 0);
                return index >= 0 && index < list.size() ? list.get(index) : NoneValue.INSTANCE;
            }
            case "joined": {
                String separator = strArg(context, args, 0);
                StringBuilder sb = new StringBuilder();
                boolean first = true;
                for (Object element : readList(name, receiver)) {
                    if (!first) {
                        sb.append(separator);
                    }
                    first = false;
                    sb.append(Values.displayString(element));
                }
                return sb.toString();
            }
            case "count": {
                Object needle = evaluateArg(context, args, 0);
                int count = 0;
                for (Object element : readList(name, receiver)) {
                    if (Values.objectsEqual(element, needle)) {
                        count++;
                    }
                }
                return count;
            }
            case "sorted": {
                List<Object> copy = requireListCopy(name, receiver);
                sortNatural(name, copy, false);
                return copy;
            }
            case "sorted_by":
            case "sorted_by_desc": {
                List<Object> copy = requireListCopy(name, receiver);
                SwoftCallable key = requireCallable(name, evaluateArg(context, args, 0));
                sortByKey(context, name, copy, key, name.endsWith("_desc"));
                return copy;
            }
            case "reversed": {
                List<Object> copy = requireListCopy(name, receiver);
                java.util.Collections.reverse(copy);
                return copy;
            }
            case "shuffled": {
                List<Object> copy = requireListCopy(name, receiver);
                shuffleInPlace(copy);
                return copy;
            }
            case "filtered": {
                List<Object> copy = requireListCopy(name, receiver);
                SwoftCallable predicate = requireCallable(name, evaluateArg(context, args, 0));
                List<Object> out = new ArrayList<>();
                for (Object element : copy) {
                    if (Values.toBoolean(applyKey(context, name, predicate, element))) {
                        out.add(element);
                    }
                }
                return out;
            }
            case "mapped": {
                List<Object> copy = requireListCopy(name, receiver);
                SwoftCallable transform = requireCallable(name, evaluateArg(context, args, 0));
                List<Object> out = new ArrayList<>(copy.size());
                for (Object element : copy) {
                    out.add(applyKey(context, name, transform, element));
                }
                return out;
            }
            case "taken": {
                List<Object> list = readList(name, receiver);
                int n = Math.clamp(intArg(context, name, args, 0), 0, list.size());
                return new ArrayList<>(list.subList(0, n));
            }
            case "dropped": {
                List<Object> list = readList(name, receiver);
                int n = Math.clamp(intArg(context, name, args, 0), 0, list.size());
                return new ArrayList<>(list.subList(n, list.size()));
            }
            case "min_by":
            case "max_by": {
                List<Object> copy = requireListCopy(name, receiver);
                SwoftCallable key = requireCallable(name, evaluateArg(context, args, 0));
                return extreme(context, name, copy, key, name.equals("max_by"));
            }
            // ---- mutating statement methods (live list) ----
            case "add":
                liveList(name, receiver).add(evaluateArg(context, args, 0));
                return receiver;
            case "add_all": {
                List<Object> other = requireListCopy(name, evaluateArg(context, args, 0));
                liveList(name, receiver).addAll(other);
                return receiver;
            }
            case "remove": {
                List<Object> live = liveList(name, receiver);
                Object needle = evaluateArg(context, args, 0);
                int index = listIndexOf(live, needle);
                if (index >= 0) {
                    live.remove(index);
                }
                return receiver;
            }
            case "remove_at": {
                List<Object> live = liveList(name, receiver);
                int index = intArg(context, name, args, 0);
                if (index >= 0 && index < live.size()) {
                    live.remove(index);
                }
                return receiver;
            }
            case "clear":
                liveList(name, receiver).clear();
                return receiver;
            case "insert": {
                List<Object> live = liveList(name, receiver);
                int index = Math.clamp(intArg(context, name, args, 0), 0, live.size());
                live.add(index, evaluateArg(context, args, 1));
                return receiver;
            }
            default:
                throw new ScriptError("unknown list method '" + name + "'");
        }
    }

    // ------------------------- string methods -------------------------

    private static Object stringMethod(ExecutionContext context, String str, String name,
            List<Expression> args) {
        switch (name) {
            case "length":
                return str.length();
            case "upper":
                return str.toUpperCase(Locale.ROOT);
            case "lower":
                return str.toLowerCase(Locale.ROOT);
            case "trimmed":
                return str.trim();
            case "contains":
                return str.contains(strArg(context, args, 0));
            case "starts_with":
                return str.startsWith(strArg(context, args, 0));
            case "ends_with":
                return str.endsWith(strArg(context, args, 0));
            case "replace":
                return str.replace(strArg(context, args, 0), strArg(context, args, 1));
            case "split": {
                String separator = strArg(context, args, 0);
                List<Object> out = new ArrayList<>();
                // literal (non-regex) split; empty separator splits every char
                if (separator.isEmpty()) {
                    for (int i = 0; i < str.length(); i++) {
                        out.add(String.valueOf(str.charAt(i)));
                    }
                } else {
                    for (String part : str.split(java.util.regex.Pattern.quote(separator), -1)) {
                        out.add(part);
                    }
                }
                return out;
            }
            case "substring": {
                int begin = Math.clamp(intArg(context, name, args, 0), 0, str.length());
                int end = Math.clamp(intArg(context, name, args, 1), begin, str.length());
                return str.substring(begin, end);
            }
            case "index_of": {
                int index = str.indexOf(strArg(context, args, 0));
                return index >= 0 ? (Object) index : NoneValue.INSTANCE;
            }
            case "repeated": {
                int n = Math.max(0, intArg(context, name, args, 0));
                return str.repeat(n);
            }
            case "reversed":
                return new StringBuilder(str).reverse().toString();
            case "padded_left":
                return pad(str, intArg(context, name, args, 0), strArg(context, args, 1), true);
            case "padded_right":
                return pad(str, intArg(context, name, args, 0), strArg(context, args, 1), false);
            case "first_chars": {
                int n = Math.clamp(intArg(context, name, args, 0), 0, str.length());
                return str.substring(0, n);
            }
            case "last_chars": {
                int n = Math.clamp(intArg(context, name, args, 0), 0, str.length());
                return str.substring(str.length() - n);
            }
            default:
                throw new ScriptError("unknown string method '" + name + "'");
        }
    }

    // ------------------------- method helpers -------------------------

    /** Read-only view of a list receiver (any Collection), copied if needed. */
    private static List<Object> readList(String method, Object value) {
        if (value instanceof List<?> list) {
            @SuppressWarnings("unchecked")
            List<Object> typed = (List<Object>) list;
            return typed;
        }
        if (value instanceof Collection<?> collection) {
            return new ArrayList<>(collection);
        }
        throw new ScriptError(method + "() expects a list, got: " + Values.displayString(value));
    }

    /** The live, mutable list backing a receiver; required by mutating methods. */
    private static List<Object> liveList(String method, Object value) {
        if (value instanceof List<?> list) {
            @SuppressWarnings("unchecked")
            List<Object> typed = (List<Object>) list;
            return typed;
        }
        throw new ScriptError(method + "() can only mutate a list value, got: "
                + Values.displayString(value));
    }

    /** First index of a value by numeric-aware equality, or -1 if absent. */
    private static int listIndexOf(List<Object> list, Object needle) {
        for (int i = 0; i < list.size(); i++) {
            if (Values.objectsEqual(list.get(i), needle)) {
                return i;
            }
        }
        return -1;
    }

    /** Fisher-Yates shuffle in place via ThreadLocalRandom. */
    private static void shuffleInPlace(List<Object> list) {
        for (int i = list.size() - 1; i > 0; i--) {
            int j = ThreadLocalRandom.current().nextInt(i + 1);
            Object tmp = list.get(i);
            list.set(i, list.get(j));
            list.set(j, tmp);
        }
    }

    /** Pad a string to width using the first char of pad (or a space). */
    private static String pad(String str, int width, String pad, boolean left) {
        int missing = width - str.length();
        if (missing <= 0) {
            return str;
        }
        char fill = pad.isEmpty() ? ' ' : pad.charAt(0);
        String padding = String.valueOf(fill).repeat(missing);
        return left ? padding + str : str + padding;
    }

    private static int intArg(ExecutionContext context, String method, List<Expression> args,
            int index) {
        Object value = evaluateArg(context, args, index);
        if (value instanceof Number number) {
            return number.intValue();
        }
        throw new ScriptError(method + "() expects a number argument, got: "
                + Values.displayString(value));
    }

    private static String strArg(ExecutionContext context, List<Expression> args, int index) {
        return (String) Coercions.toStringValue(evaluateArg(context, args, index));
    }

    /** A map builtin's first argument must be a script map. */
    private static MapValue requireMap(String function, Object value) {
        if (value instanceof MapValue map) {
            return map;
        }
        throw new ScriptError(function + "() expects a map, got: "
                + Values.displayString(value));
    }

    /**
     * A map key is String or Integer (the checker enforces one type per map);
     * an Integer key is preserved as a boxed Integer, a String stays a String.
     * none is never a legal key.
     */
    private static Object mapKey(String function, Object value) {
        if (NoneValue.isNone(value)) {
            throw new ScriptError(function + "() key cannot be none");
        }
        return Values.coerceMapKey(value);
    }

    /**
     * polar_storage_loader config: an object literal with the same keys
     * as the storage{} backend block, or a bare string (files directory).
     */
    private static net.swofty.model.StorageBackendModel storageBackendOf(Object config) {
        if (config instanceof String path) {
            return net.swofty.model.StorageBackendModel.files(path);
        }
        if (config instanceof java.util.Map<?, ?> map) {
            java.util.function.Function<String, String> str = key -> {
                Object value = map.get(key);
                return NoneValue.isNone(value) ? null : String.valueOf(value);
            };
            String kind = str.apply("kind");
            Object portValue = map.get("port");
            return new net.swofty.model.StorageBackendModel(
                    kind != null ? kind : "files",
                    str.apply("path") != null ? str.apply("path")
                            : str.apply("dir") != null ? str.apply("dir") : str.apply("file"),
                    str.apply("host"),
                    portValue instanceof Number number ? number.intValue() : 0,
                    str.apply("database"),
                    str.apply("user"),
                    str.apply("password"),
                    str.apply("uri") != null ? str.apply("uri") : str.apply("url"));
        }
        throw new ScriptError("polar_storage_loader() expects a backend config object "
                + "({ kind: \"sqlite\", path: ... }) or a files directory string, got: "
                + Values.displayString(config));
    }

    // ------------------------------------------------------------------
    // collections pass: sorting helpers (all non-mutating, stable)
    // ------------------------------------------------------------------

    /** A sort/random builtin's list argument, copied to a fresh ArrayList. */
    private static List<Object> requireListCopy(String function, Object value) {
        if (value instanceof Collection<?> collection) {
            return new ArrayList<>(collection);
        }
        throw new ScriptError(function + "() expects a list, got: "
                + Values.displayString(value));
    }

    /** A key/comparator argument that must be a first-class function value. */
    private static SwoftCallable requireCallable(String function, Object value) {
        if (value instanceof SwoftCallable callable) {
            return callable;
        }
        throw new ScriptError(function + "() expects a function key, got: "
                + Values.displayString(value));
    }

    /**
     * Numeric-aware comparison for sorting (numbers numeric, strings
     * lexicographic); an uncomparable pair is a runtime ScriptError rather
     * than the raw RuntimeException {@link Values#compareObjects} throws.
     */
    private static int compareForSort(String function, Object a, Object b) {
        try {
            return Values.compareObjects(a, b);
        } catch (ScriptError e) {
            throw e;
        } catch (RuntimeException e) {
            throw new ScriptError(function + "(): cannot compare "
                    + Values.displayString(a) + " and " + Values.displayString(b)
                    + " (sortable values are all-Number or all-String)");
        }
    }

    /** Natural-order sort of a list of Number or String, in place on the copy. */
    private static void sortNatural(String function, List<Object> list, boolean desc) {
        Comparator<Object> comparator = (a, b) -> compareForSort(function, a, b);
        list.sort(desc ? comparator.reversed() : comparator);
    }

    /**
     * Sort a list copy by the key the lambda returns per element. Keys are
     * computed once each (not per comparison) so the lambda runs O(n); the
     * subsequent {@link List#sort} is a stable TimSort, so equal keys keep
     * input order (descending negates the comparator, tie order preserved).
     */
    private static void sortByKey(ExecutionContext context, String function,
            List<Object> list, SwoftCallable key, boolean desc) {
        List<Object[]> keyed = new ArrayList<>(list.size());
        for (Object element : list) {
            keyed.add(new Object[] { element, applyKey(context, function, key, element) });
        }
        Comparator<Object[]> comparator = (a, b) -> compareForSort(function, a[1], b[1]);
        keyed.sort(desc ? comparator.reversed() : comparator);
        for (int i = 0; i < keyed.size(); i++) {
            list.set(i, keyed.get(i)[0]);
        }
    }

    /**
     * The element whose lambda key is largest (max) or smallest (min); a
     * single pass, first-wins on ties. none for an empty list.
     */
    private static Object extreme(ExecutionContext context, String function,
            List<Object> list, SwoftCallable key, boolean max) {
        if (list.isEmpty()) {
            return NoneValue.INSTANCE;
        }
        Object best = list.get(0);
        Object bestKey = applyKey(context, function, key, best);
        for (int i = 1; i < list.size(); i++) {
            Object element = list.get(i);
            Object elementKey = applyKey(context, function, key, element);
            int cmp = compareForSort(function, elementKey, bestKey);
            if (max ? cmp > 0 : cmp < 0) {
                best = element;
                bestKey = elementKey;
            }
        }
        return best;
    }

    /**
     * Build a NEW MapValue whose entries are inserted in sorted order (a
     * LinkedHashMap, so iteration/serialization walk that order). The sort key
     * is either the arity-2 lambda's return (sort_map_by) or the built-in
     * key/value extractor (sort_by_key / sort_by_value). Stable ties.
     */
    private static MapValue sortedMap(String function, MapValue map, boolean desc,
            BiFunction<Object, Object, Object> extractor,
            ExecutionContext context, SwoftCallable keyFn) {
        List<Map.Entry<Object, Object>> entries = new ArrayList<>(map.entrySet());
        List<Object[]> keyed = new ArrayList<>(entries.size());
        for (Map.Entry<Object, Object> entry : entries) {
            Object sortKey = keyFn != null
                    ? applyKey(context, function, keyFn, entry.getKey(), entry.getValue())
                    : extractor.apply(entry.getKey(), entry.getValue());
            keyed.add(new Object[] { entry, sortKey });
        }
        Comparator<Object[]> comparator = (a, b) -> compareForSort(function, a[1], b[1]);
        keyed.sort(desc ? comparator.reversed() : comparator);
        MapValue out = new MapValue();
        for (Object[] pair : keyed) {
            @SuppressWarnings("unchecked")
            Map.Entry<Object, Object> entry = (Map.Entry<Object, Object>) pair[0];
            out.put(entry.getKey(), entry.getValue());
        }
        return out;
    }

    /** Invoke a key lambda with the given arguments; arity is checked. */
    private static Object applyKey(ExecutionContext context, String function,
            SwoftCallable key, Object... values) {
        if (key.params().size() != values.length) {
            throw new ScriptError(function + "() key function expects "
                    + values.length + " argument(s), got a "
                    + key.params().size() + "-parameter function");
        }
        return context.callCallable(key, List.of(values));
    }

    private static Object minMax(String function, Object a, Object b, boolean min) {
        if (!(a instanceof Number) || !(b instanceof Number)) {
            throw new ScriptError(function + "() expects two numbers, got: "
                    + Values.displayString(a) + ", " + Values.displayString(b));
        }
        if (a instanceof Integer && b instanceof Integer) {
            return min ? Math.min((Integer) a, (Integer) b) : Math.max((Integer) a, (Integer) b);
        }
        double left = ((Number) a).doubleValue();
        double right = ((Number) b).doubleValue();
        return min ? Math.min(left, right) : Math.max(left, right);
    }

    private static Object evaluateArg(ExecutionContext context, List<Expression> args, int index) {
        return index < args.size() ? context.evaluate(args.get(index)) : null;
    }

    // ------------------------------------------------------------------
    // W-stdlib: random / location / color / parse / type helpers
    // ------------------------------------------------------------------

    /**
     * Per-thread seeded generator installed by random_seed(); null until then.
     * When present the design-named random_* draws use it (reproducible tests);
     * otherwise they fall back to ThreadLocalRandom. The pre-existing random /
     * random_float / random_in builtins are untouched and always use
     * ThreadLocalRandom.
     */
    private static final ThreadLocal<java.util.Random> SEEDED_RNG = new ThreadLocal<>();

    private static java.util.Random rng() {
        java.util.Random seeded = SEEDED_RNG.get();
        return seeded != null ? seeded : ThreadLocalRandom.current();
    }

    /** Resolve a Location (Pos) argument for the B7 location/vector builtins. */
    private static Pos requireLocationArg(ExecutionContext context, String function,
            List<Expression> args, int index) {
        Object value = evaluateArg(context, args, index);
        if (value instanceof Pos pos) {
            return pos;
        }
        throw new ScriptError(function + "() expects a location, got: "
                + Values.displayString(value));
    }

    /** parse(source, TypeName) -> optional<T>: total, none on any parse failure. */
    private static Object parseAs(String source, String typeName) {
        String trimmed = source.trim();
        try {
            switch (typeName) {
                case "Integer":
                case "Int":
                case "int":
                    return Integer.parseInt(trimmed);
                case "Double":
                case "double":
                case "Number":
                    return Double.parseDouble(trimmed);
                case "Boolean":
                case "Bool":
                case "bool":
                    if (trimmed.equalsIgnoreCase("true")) {
                        return true;
                    }
                    if (trimmed.equalsIgnoreCase("false")) {
                        return false;
                    }
                    return NoneValue.INSTANCE;
                case "String":
                    return source;
                default:
                    // non-scalar target types cannot be parsed from a string
                    return NoneValue.INSTANCE;
            }
        } catch (NumberFormatException e) {
            return NoneValue.INSTANCE;
        }
    }

    /** Legacy (&/§) color + format codes, including &#rrggbb hex sequences. */
    private static final java.util.regex.Pattern LEGACY_CODE =
            java.util.regex.Pattern.compile("(?i)[&§](#[0-9a-f]{6}|[0-9a-fk-or])");

    /**
     * Plain text with all formatting removed: MiniMessage tags are dropped by
     * rendering to a Component and back to plain text, then any remaining legacy
     * &/§ codes are stripped.
     */
    private static String stripColor(String source) {
        String plain = net.swofty.TextFormat.plain(net.swofty.TextFormat.component(source));
        return LEGACY_CODE.matcher(plain).replaceAll("");
    }

    /**
     * Convert legacy &/§ color and format codes (and &#rrggbb / §#rrggbb hex)
     * into the MiniMessage tags the send path understands. Unknown codes pass
     * through untouched.
     */
    private static String legacyToMini(String source) {
        StringBuilder out = new StringBuilder(source.length());
        int len = source.length();
        for (int i = 0; i < len; i++) {
            char c = source.charAt(i);
            if ((c == '&' || c == '§') && i + 1 < len) {
                char next = source.charAt(i + 1);
                if (next == '#' && i + 7 < len) {
                    String hex = source.substring(i + 2, i + 8);
                    if (hex.chars().allMatch(ch -> Character.digit(ch, 16) >= 0)) {
                        out.append("<#").append(hex.toLowerCase(Locale.ROOT)).append('>');
                        i += 7;
                        continue;
                    }
                }
                String tag = miniTagFor(Character.toLowerCase(next));
                if (tag != null) {
                    out.append(tag);
                    i++;
                    continue;
                }
            }
            out.append(c);
        }
        return out.toString();
    }

    private static String miniTagFor(char code) {
        return switch (code) {
            case '0' -> "<black>";
            case '1' -> "<dark_blue>";
            case '2' -> "<dark_green>";
            case '3' -> "<dark_aqua>";
            case '4' -> "<dark_red>";
            case '5' -> "<dark_purple>";
            case '6' -> "<gold>";
            case '7' -> "<gray>";
            case '8' -> "<dark_gray>";
            case '9' -> "<blue>";
            case 'a' -> "<green>";
            case 'b' -> "<aqua>";
            case 'c' -> "<red>";
            case 'd' -> "<light_purple>";
            case 'e' -> "<yellow>";
            case 'f' -> "<white>";
            case 'k' -> "<obfuscated>";
            case 'l' -> "<bold>";
            case 'm' -> "<strikethrough>";
            case 'n' -> "<underlined>";
            case 'o' -> "<italic>";
            case 'r' -> "<reset>";
            default -> null;
        };
    }

    /** Normalize a hex color argument ("#rrggbb", "rrggbb", "<#rrggbb>") to rrggbb. */
    private static String normalizeHex(String raw) {
        String hex = raw.trim();
        if (hex.startsWith("<#") && hex.endsWith(">")) {
            hex = hex.substring(2, hex.length() - 1);
        }
        if (hex.startsWith("#")) {
            hex = hex.substring(1);
        }
        return hex.toLowerCase(Locale.ROOT);
    }

    /** type_of(obj): the language-level type name of a runtime value. */
    private static String typeName(Object value) {
        if (value == null || NoneValue.isNone(value)) {
            return "none";
        }
        if (value instanceof Integer || value instanceof Long) {
            return "Integer";
        }
        if (value instanceof Double || value instanceof Float) {
            return "Double";
        }
        if (value instanceof Boolean) {
            return "Boolean";
        }
        if (value instanceof String) {
            return "String";
        }
        if (value instanceof Player) {
            return "Player";
        }
        if (value instanceof Vec) {
            return "Vec";
        }
        if (value instanceof Pos) {
            return "Location";
        }
        if (value instanceof ItemStack) {
            return "Item";
        }
        if (value instanceof net.swofty.blocks.BlockValue) {
            return "Block";
        }
        if (value instanceof net.swofty.displays.SwoftDisplay) {
            return "Display";
        }
        if (value instanceof net.minestom.server.entity.Entity) {
            return "Entity";
        }
        if (value instanceof Instance) {
            return "World";
        }
        if (value instanceof MapValue) {
            return "map";
        }
        if (value instanceof Collection) {
            return "list";
        }
        return value.getClass().getSimpleName();
    }

    private static Number evaluateNumberArg(ExecutionContext context, String function,
            List<Expression> args, int index) {
        Object value = evaluateArg(context, args, index);
        if (value instanceof Number) {
            return (Number) value;
        }
        System.err.println("Error: " + function + "() expects a number argument, got: " + value);
        return null;
    }

    private static Number requireNumberArg(ExecutionContext context, String function,
            List<Expression> args, int index) {
        Object value = evaluateArg(context, args, index);
        if (value instanceof Number) {
            return (Number) value;
        }
        throw new ScriptError(function + "() expects a number argument, got: "
                + Values.displayString(value));
    }

    /**
     * Resolve a state-store entity argument: a live Minestom entity (player,
     * mob, projectile, plain entity), or a script display unwrapped to its
     * backing entity, so state can key off displays too.
     */
    private static net.minestom.server.entity.Entity requireEntityArg(ExecutionContext context,
            String function, List<Expression> args, int index) {
        Object value = evaluateArg(context, args, index);
        if (value instanceof net.minestom.server.entity.Entity entity) {
            return entity;
        }
        if (value instanceof net.swofty.displays.SwoftDisplay display) {
            return display.entity();
        }
        throw new ScriptError(function + "() expects an entity, got: "
                + Values.displayString(value));
    }

    /**
     * Resolve a String argument at {@code index}, coercing non-string values the
     * same way the language coerces everywhere else.
     */
    private static String requireStringArg(ExecutionContext context, String function,
            List<Expression> args, int index) {
        Object value = Coercions.toStringValue(evaluateArg(context, args, index));
        if (value instanceof String s) {
            return s;
        }
        throw new ScriptError(function + "() expects a String argument, got: "
                + Values.displayString(value));
    }

}
