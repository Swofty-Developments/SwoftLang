package net.swofty;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.event.GlobalEventHandler;
import net.minestom.server.event.player.AsyncPlayerConfigurationEvent;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.InstanceManager;
import net.minestom.server.instance.block.Block;

public class Bootstrap {
    private static SwoftLangEngine swoftLangEngine;

    public static void main(String[] args) {
        LibraryLoader loader = new LibraryLoader();

        // Initialize Minestom server
        MinecraftServer server = MinecraftServer.init();
        InstanceManager instanceManager = MinecraftServer.getInstanceManager();
        GlobalEventHandler globalEventHandler = MinecraftServer.getGlobalEventHandler();
        InstanceContainer instanceContainer = instanceManager.createInstanceContainer();

        // Set the ChunkGenerator
        instanceContainer.setGenerator(unit -> unit.modifier().fillHeight(0, 40, Block.GRASS_BLOCK));

        // Add an event callback to specify the spawning instance (and the spawn position)
        globalEventHandler.addListener(AsyncPlayerConfigurationEvent.class, event -> {
            final Player player = event.getPlayer();
            event.setSpawningInstance(instanceContainer);
            player.setRespawnPoint(new Pos(0, 42, 0));
        });

        // Initialize and load SwoftLang scripts
        swoftLangEngine = new SwoftLangEngine();
        swoftLangEngine.initialize();

        // Register all components with your server
        swoftLangEngine.register();

        // Start the server
        server.start("0.0.0.0", 25565);
    }

    /**
     * Access the SwoftLang engine from other parts of your application
     */
    public static SwoftLangEngine getSwoftLangEngine() {
        return swoftLangEngine;
    }
}