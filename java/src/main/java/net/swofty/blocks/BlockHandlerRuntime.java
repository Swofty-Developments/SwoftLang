package net.swofty.blocks;

import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import net.kyori.adventure.key.Key;
import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.minestom.server.event.GlobalEventHandler;
import net.minestom.server.event.player.PlayerBlockPlaceEvent;
import net.minestom.server.instance.block.BlockHandler;
import net.swofty.model.BlockCallbackModel;
import net.swofty.model.BlockHandlerModel;
import net.swofty.runtime.Values;

/**
 * Runtime for {@code block_handler "id" { ... }} declarations (W-blocks): a
 * first-class {@link BlockHandler} whose {@code onPlace}/{@code onDestroy}/
 * {@code onInteract}/{@code onTouch}/{@code tick} callbacks route through the
 * SwoftLang {@link net.swofty.ASTExecutor}. This generalizes the native
 * dispenser special-case into a data-driven, script-authored construct.
 *
 * <p>Handlers are registered with the {@link net.minestom.server.instance.block.BlockManager}
 * under the block's namespaced id (so chunk load rehydrates them) and attached
 * to freshly placed blocks of that id. The concrete {@link ScriptBlockHandler}
 * resolves its behaviour from the live {@link #MODELS} map on every callback, so
 * {@link #teardown()} — clearing the map on hot-reload — instantly makes every
 * live handler inert without needing an unregister API Minestom does not expose.
 */
public final class BlockHandlerRuntime {

    /** Declared handlers by namespaced block id; cleared on teardown. */
    private static final Map<String, BlockHandlerModel> MODELS = new ConcurrentHashMap<>();

    /** Block ids whose handler supplier has been given to the BlockManager. */
    private static final Set<String> DECLARED = ConcurrentHashMap.newKeySet();

    private static volatile boolean listenerInstalled = false;

    private BlockHandlerRuntime() {
    }

    /** Install the one-time place listener that attaches handlers on place. */
    public static synchronized void init() {
        if (listenerInstalled) {
            return;
        }
        listenerInstalled = true;
        GlobalEventHandler handler = MinecraftServer.getGlobalEventHandler();
        handler.addListener(PlayerBlockPlaceEvent.class, event -> {
            String id = event.getBlock().key().asString();
            if (MODELS.containsKey(id)) {
                event.setBlock(event.getBlock().withHandler(new ScriptBlockHandler(id)));
            }
        });
    }

    /** Clear all declared handlers (live handlers resolve to inert). */
    public static void teardown() {
        MODELS.clear();
    }

    /** Register one declared {@code block_handler}. */
    public static void register(BlockHandlerModel model) {
        String id = normalize(model.id());
        MODELS.put(id, model);
        if (DECLARED.add(id)) {
            // supplier rehydrates the handler on chunk load; behaviour is
            // resolved live from MODELS so a reload without this id goes inert
            MinecraftServer.getBlockManager().registerHandler(id,
                    () -> new ScriptBlockHandler(id));
        }
    }

    static BlockHandlerModel model(String id) {
        return MODELS.get(id);
    }

    private static String normalize(String id) {
        return id.contains(":") ? id.toLowerCase() : "minecraft:" + id.toLowerCase();
    }

    private static CommandSender senderOr(Player player) {
        return player != null ? player : BlockCallbacks.consoleSender();
    }

    /**
     * The concrete {@link BlockHandler} bound to one block id. All behaviour is
     * looked up from {@link #MODELS} at call time, so it is safe to keep the
     * instance attached to placed blocks across hot-reloads: after teardown the
     * lookup returns null and every callback no-ops.
     */
    static final class ScriptBlockHandler implements BlockHandler {
        private final String id;
        private final Key key;

        ScriptBlockHandler(String id) {
            this.id = id;
            this.key = Key.key(id);
        }

        @Override
        public Key getKey() {
            return key;
        }

        @Override
        public boolean isTickable() {
            BlockHandlerModel model = MODELS.get(id);
            return model != null && model.callback("tick") != null;
        }

        @Override
        public void onPlace(BlockHandler.Placement placement) {
            BlockCallbackModel cb = callback("on_place");
            if (cb == null) {
                return;
            }
            Player player = placement instanceof BlockHandler.PlayerPlacement pp
                    ? pp.getPlayer() : null;
            Map<String, Object> vars = BlockCallbacks.bind(cb, player,
                    BlockCallbacks.location(placement.getBlockPosition()),
                    new BlockValue(placement.getBlock()));
            BlockCallbacks.run(senderOr(player), cb, vars, label());
        }

        @Override
        public void onDestroy(BlockHandler.Destroy destroy) {
            BlockCallbackModel cb = callback("on_destroy");
            if (cb == null) {
                return;
            }
            Player player = destroy instanceof BlockHandler.PlayerDestroy pd
                    ? pd.getPlayer() : null;
            Map<String, Object> vars = BlockCallbacks.bind(cb,
                    BlockCallbacks.location(destroy.getBlockPosition()),
                    new BlockValue(destroy.getBlock()));
            BlockCallbacks.run(senderOr(player), cb, vars, label());
        }

        @Override
        public boolean onInteract(BlockHandler.Interaction interaction) {
            BlockCallbackModel cb = callback("on_interact");
            if (cb == null) {
                return true;
            }
            Player player = interaction.getPlayer();
            Map<String, Object> vars = BlockCallbacks.bind(cb, player,
                    BlockCallbacks.location(interaction.getBlockPosition()),
                    new BlockValue(interaction.getBlock()));
            Object result = BlockCallbacks.runReturning(senderOr(player), cb, vars, label());
            // "return handled?"; default to handled when the body falls through
            return result == null || Values.toBoolean(result);
        }

        @Override
        public void onTouch(BlockHandler.Touch touch) {
            BlockCallbackModel cb = callback("on_touch");
            if (cb == null) {
                return;
            }
            Map<String, Object> vars = BlockCallbacks.bind(cb, touch.getTouching(),
                    BlockCallbacks.location(touch.getBlockPosition()));
            BlockCallbacks.run(BlockCallbacks.consoleSender(), cb, vars, label());
        }

        @Override
        public void tick(BlockHandler.Tick tick) {
            BlockCallbackModel cb = callback("tick");
            if (cb == null) {
                return;
            }
            Map<String, Object> vars = BlockCallbacks.bind(cb,
                    BlockCallbacks.location(tick.getBlockPosition()),
                    new BlockValue(tick.getBlock()));
            BlockCallbacks.run(BlockCallbacks.consoleSender(), cb, vars, label());
        }

        private BlockCallbackModel callback(String name) {
            BlockHandlerModel model = MODELS.get(id);
            return model != null ? model.callback(name) : null;
        }

        private String label() {
            return "block_handler '" + id + "'";
        }
    }
}
