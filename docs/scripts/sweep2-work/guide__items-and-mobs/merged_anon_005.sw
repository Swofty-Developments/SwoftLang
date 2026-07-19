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

command "ghoul" {
    execute {
        spawn mob "crypt_ghoul" at location(10, 64, 20) as m
        set m.health to m.max_health / 2
        send "<gray>Spawned ${m.custom_id} at half health." to sender
    }
}

command "cleanse" {
    execute {
        loop all_mobs("crypt_ghoul") as g {
            despawn g
        }
        send "<green>The crypt is quiet." to sender
    }
}
