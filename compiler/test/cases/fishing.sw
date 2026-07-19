// Phase-8 native fishing engine surface: fishing_loot tables (medium/world
// matching, weighted item/mob catches, per-catch messages), the server{}
// fishing bite window, and the four curated fishing events.

item "enchanted_fish" {
    material: "COD"
    name: "<aqua>Enchanted Fish"
    rarity: rare
}

mob "sea_walker" {
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

event PlayerCastRod {
    execute {
        if player.world.time > 100000 {
            cancel event
        }
    }
}

event FishBite {
    execute {
        send "something bit near ${hook_location.x}, ${hook_location.z}" to player
    }
}

event PlayerCatchFish {
    execute {
        if event.caught_mob exists {
            send "a creature emerges..." to player
            halt
        }
        if event.caught_item exists {
            send "you caught ${event.caught_item.name}!" to player
            set event.caught_item to item("SALMON")
        }
    }
}

event PlayerReelIn {
    execute {
        send "reeled in" to player
    }
}
