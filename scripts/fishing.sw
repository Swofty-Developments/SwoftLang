// Phase-8 native fishing engine showcase: declarative weighted loot tables
// (medium + optional world matching, custom items and mobs, per-catch
// messages), the server{} bite window, and the four typed fishing events.

item GlimmeringCod {
    material: "COD"
    name: "<aqua>Glimmering Cod"
    rarity: rare
    lore {
        line "<gray>It hums faintly."
    }
}

mob SeaWalker {
    type: "ZOMBIE"
    name: "<dark_aqua>Sea Walker"
    health: 40
    ai: melee
}

// Matched by medium + world name; the most specific table wins and the
// built-in vanilla table serves anything unmatched.
fishing_loot "overworld_water" {
    medium: water
    world: "world"
    catch item "COD" weight 40
    catch item "SALMON" weight 25
    catch item "glimmering_cod" weight 5 message "<aqua>It glimmers in your hands."
    catch mob "sea_walker" weight 3 message "<red>Something walked out of the water..."
    catch item "PUFFERFISH" weight 10 message "<yellow>Careful, it puffs!"
}

fishing_loot "any_lava" {
    medium: lava
    catch item "MAGMA_CREAM" weight 8
    catch item "BLAZE_ROD" weight 2 message "<gold>Still warm."
}

server {
    motd: "Gone fishin'"
    fishing {
        min_bite: 4 seconds
        max_bite: 20 seconds
    }
}

// The four typed fishing events fold onto the rod holder: `player` binds to the
// Player. Each fires at the matching moment of the cast/bite/catch/reel cycle.
Player {
    // fires before the bobber exists
    on_cast_rod {
        if player.world.time > 100000 {
            send "<gray>The fish are asleep." to player
        }
    }

    // the bobber dipped: reel within the window to land the catch
    on_fish_bite {
        send "<aqua>Something's biting..." to player
    }

    // the catch emerges
    on_catch_fish {
        send "<green>You landed something!" to player
    }

    on_reel_in {
        send "<gray>line reeled in" to player
    }
}
