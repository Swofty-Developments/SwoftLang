item "rotten_scimitar" {
    material: "GOLDEN_SWORD"
    name: "<gray>Rotten Scimitar"
    rarity: uncommon

    tags {
        damage: 40
    }
}

mob "crypt_ghoul" {
    type: "ZOMBIE"
    name: "<red>Crypt Ghoul <green>${mob.health}<red>❤"
    health: 200
    damage: 25
    speed: 0.3
    ai: melee

    drops {
        item "rotten_scimitar" chance 0.05 amount 1
        item "ROTTEN_FLESH" chance 0.5 amount 2
    }

    on_spawn {
        broadcast "<gray>A ${mob.custom_id} rises from the crypt..."
    }

    on_death {
        if killer exists {
            send "<green>You slew the Crypt Ghoul!" to killer
        }
    }

    on_attack {
        send "<red>The ghoul rakes at you!" to victim
    }
}
