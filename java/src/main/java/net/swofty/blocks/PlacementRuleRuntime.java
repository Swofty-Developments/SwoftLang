package net.swofty.blocks;

import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Point;
import net.minestom.server.instance.block.Block;
import net.minestom.server.instance.block.BlockFace;
import net.minestom.server.instance.block.rule.BlockPlacementRule;
import net.swofty.model.BlockCallbackModel;
import net.swofty.model.PlacementRuleModel;
import net.swofty.nativebridge.execution.commands.blocks.SetBlockStatement;
import net.swofty.props.NoneValue;
import net.swofty.runtime.MapValue;

/**
 * Runtime for {@code placement_rule for "id" { ... }} declarations (W-blocks):
 * wraps a native {@link BlockPlacementRule} whose {@code blockPlace} /
 * {@code blockUpdate} callbacks run in SwoftLang. Minestom ships <em>zero</em>
 * default placement rules, so this is how stairs/slabs/logs/fences/etc. compute
 * orientation and neighbor connections — one rule per block family, authored in
 * script.
 *
 * <p>The {@code on_place} callback receives {@code (location, face, cursor,
 * against, player)} and returns the oriented {@link BlockValue} to place;
 * {@code on_update} receives {@code (location, block, neighbors)} — the six
 * face-adjacent blocks — and returns the recomputed block. As with block
 * handlers, behaviour is resolved live from {@link #MODELS} so {@link #teardown()}
 * makes a registered rule fall back to vanilla passthrough (Minestom exposes no
 * unregister for placement rules).
 */
public final class PlacementRuleRuntime {

    private static final Map<String, PlacementRuleModel> MODELS = new ConcurrentHashMap<>();
    private static final Set<String> REGISTERED = ConcurrentHashMap.newKeySet();

    private PlacementRuleRuntime() {
    }

    /** Placement rules need no global listener; register handles everything. */
    public static void init() {
        // no-op: kept for symmetry with the other block runtimes
    }

    /** Clear all declared rules (registered rules fall back to passthrough). */
    public static void teardown() {
        MODELS.clear();
    }

    /** Register one declared {@code placement_rule}. */
    public static void register(PlacementRuleModel model) {
        String id = normalize(model.id());
        MODELS.put(id, model);
        if (REGISTERED.add(id)) {
            Block block = SetBlockStatement.resolveBlock(id);
            MinecraftServer.getBlockManager()
                    .registerBlockPlacementRule(new ScriptPlacementRule(block, id));
        }
    }

    private static String normalize(String id) {
        return id.contains(":") ? id.toLowerCase() : "minecraft:" + id.toLowerCase();
    }

    /** Unit block offset for a face (NORTH=-z, SOUTH=+z, EAST=+x, ...). */
    private static int[] offset(BlockFace face) {
        return switch (face) {
            case NORTH -> new int[] {0, 0, -1};
            case SOUTH -> new int[] {0, 0, 1};
            case EAST -> new int[] {1, 0, 0};
            case WEST -> new int[] {-1, 0, 0};
            case TOP -> new int[] {0, 1, 0};
            case BOTTOM -> new int[] {0, -1, 0};
        };
    }

    /** Coerce a callback result to a Block, falling back when it returns none. */
    private static Block toBlock(Object result, Block fallback) {
        if (result instanceof BlockValue value) {
            return value.block();
        }
        if (result instanceof String id) {
            return SetBlockStatement.resolveBlock(id);
        }
        if (result == null || NoneValue.isNone(result)) {
            return fallback;
        }
        return fallback;
    }

    /**
     * The native rule bound to one block id, resolving its script callbacks
     * live from {@link #MODELS}. When the model is gone (teardown) both hooks
     * return the block unchanged — vanilla passthrough.
     */
    static final class ScriptPlacementRule extends BlockPlacementRule {
        private final String id;

        ScriptPlacementRule(Block block, String id) {
            super(block);
            this.id = id;
        }

        @Override
        public Block blockPlace(BlockPlacementRule.PlacementState state) {
            PlacementRuleModel model = MODELS.get(id);
            if (model == null) {
                return state.block();
            }
            BlockCallbackModel cb = model.callback("on_place");
            if (cb == null) {
                return state.block();
            }
            BlockFace face = state.blockFace();
            Block.Getter getter = state.instance();
            // the block placed against sits opposite the clicked face
            Object against = NoneValue.INSTANCE;
            if (face != null) {
                int[] off = offset(face.getOppositeFace());
                Point againstPos = state.placePosition().add(off[0], off[1], off[2]);
                against = new BlockValue(getter.getBlock(againstPos));
            }
            // 'player' is the placing player's POSITION (a Pos carrying yaw/pitch)
            // — Minestom's PlacementState exposes no Player, only playerPosition().
            // It is the orientation-from-look source for stairs/doors (player.yaw).
            Object player = state.playerPosition() != null
                    ? state.playerPosition() : NoneValue.INSTANCE;
            Map<String, Object> vars = BlockCallbacks.bind(cb,
                    BlockCallbacks.location(state.placePosition()),
                    BlockCallbacks.faceName(face),
                    BlockCallbacks.vector(state.cursorPosition()),
                    against,
                    player);
            Object result = BlockCallbacks.runReturning(
                    BlockCallbacks.consoleSender(), cb, vars, label());
            return toBlock(result, state.block());
        }

        @Override
        public Block blockUpdate(BlockPlacementRule.UpdateState state) {
            PlacementRuleModel model = MODELS.get(id);
            if (model == null) {
                return state.currentBlock();
            }
            BlockCallbackModel cb = model.callback("on_update");
            if (cb == null) {
                return state.currentBlock();
            }
            Block.Getter getter = state.instance();
            Point pos = state.blockPosition();
            MapValue neighbors = new MapValue();
            for (BlockFace face : BlockFace.values()) {
                int[] off = offset(face);
                Point neighbourPos = pos.add(off[0], off[1], off[2]);
                neighbors.put(BlockCallbacks.faceName(face),
                        new BlockValue(getter.getBlock(neighbourPos)));
            }
            Map<String, Object> vars = BlockCallbacks.bind(cb,
                    BlockCallbacks.location(pos),
                    new BlockValue(state.currentBlock()),
                    neighbors);
            Object result = BlockCallbacks.runReturning(
                    BlockCallbacks.consoleSender(), cb, vars, label());
            return toBlock(result, state.currentBlock());
        }

        @Override
        public boolean isSelfReplaceable(BlockPlacementRule.Replacement replacement) {
            PlacementRuleModel model = MODELS.get(id);
            return model != null && model.selfReplaceable();
        }

        private String label() {
            return "placement_rule '" + id + "'";
        }
    }
}
