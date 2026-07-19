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
    fishing {
        min_bite: 4 seconds
        max_bite: 20 seconds
    }
}

event PlayerCastRod {
    execute {
        if player.world.time > 100000 {
            send "<gray>The fish are asleep." to player
            cancel event
        }
    }
}

event FishBite {
    execute {
        send "bite at x=${hook_location.x} z=${hook_location.z}" to player
    }
}

event PlayerCatchFish {
    execute {
        if event.caught_mob exists {
            send "<red>brace yourself..." to player
            halt
        }
        if event.caught_item exists {
            send "you landed ${event.caught_item.name}!" to player
        }
    }
}

event PlayerReelIn {
    execute {
        send "<gray>line reeled in" to player
    }
}
