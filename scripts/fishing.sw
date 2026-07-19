// Phase-8 native fishing engine showcase: declarative weighted loot tables
// (medium + optional world matching, custom items and mobs, per-catch
// messages), the server{} bite window, and the four typed fishing events.

item "glimmering_cod" {
    material: "COD"
    name: "<aqua>Glimmering Cod"
    rarity: rare
    lore {
        line "<gray>It hums faintly."
    }
}

mob "sea_walker" {
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

// Cancellable, fires before the bobber exists.
event PlayerCastRod {
    execute {
        if player.world.time > 100000 {
            send "<gray>The fish are asleep." to player
            cancel event
        }
    }
}

// The bobber dipped: reel within the window to land the catch.
event FishBite {
    execute {
        send "bite at x=${hook_location.x} z=${hook_location.z}" to player
    }
}

// Pre-delivery: caught_item is read-write (swaps the delivered stack),
// caught_mob is read-only, and cancel discards the catch entirely.
event PlayerCatchFish {
    execute {
        if event.caught_mob exists {
            send "<red>brace yourself..." to player
            halt
        }
        if event.caught_item exists {
            send "you landed ${event.caught_item.name}!" to player
            if event.caught_item.material is "minecraft:pufferfish" {
                set event.caught_item to item("COD")
                send "<gray>...swapped the puffer for a safer cod." to player
            }
        }
    }
}

event PlayerReelIn {
    execute {
        send "<gray>line reeled in" to player
    }
}
