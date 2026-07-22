// Phase-8 native fishing engine surface: fishing_loot tables (medium/world
// matching, weighted item/mob catches, per-catch messages), the server{}
// fishing bite window, and the four curated fishing events.

item EnchantedFish {
    material: "COD"
    name: "<aqua>Enchanted Fish"
    rarity: rare
}

mob SeaWalker {
    type: "ZOMBIE"
    name: "Sea Walker"
    health: 40
    ai: melee
}

fishing_loot "overworld_water" {
    medium: water
    world: "overworld"
    catch item "COD" weight 40
    catch item "enchanted_fish" weight 5
    catch mob "sea_walker" weight 3
    catch item "PUFFERFISH" weight 10 message "<yellow>Woah, a puffer!"
}

fishing_loot "nether_lava" {
    medium: lava
    catch item "MAGMA_CREAM" weight 8
    catch item "BLAZE_ROD" weight 2 message "<gold>Still warm."
}

server {
    motd: "Gone fishin'"
    fishing {
        min_bite: 3 seconds
        max_bite: 12 seconds
    }
}

Player {
    on_cast_rod {
        if player.world.time > 100000 {
            send "<red>the water is still" to player
        }
    }

    on_fish_bite {
        send "something bit nearby" to player
    }

    on_catch_fish {
        send "a creature emerges..." to player
    }

    on_reel_in {
        send "reeled in" to player
    }
}
