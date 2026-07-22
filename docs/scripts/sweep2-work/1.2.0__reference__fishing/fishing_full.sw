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

Player {
    on_cast_rod() {
        if this.world.time > 100000 {
            send "<gray>The fish are asleep." to this
        }
    }

    on_fish_bite() {
        send "<aqua>Something's biting..." to this
    }

    on_catch_fish() {
        send "<green>You landed something!" to this
    }

    on_reel_in() {
        send "<gray>line reeled in" to this
    }
}
