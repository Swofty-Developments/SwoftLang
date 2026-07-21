// Phase-5 custom mobs showcase (design 5B).
// crypt_ghoul: melee zombie with a live health nametag, custom + vanilla
// drops (the scimitar chains to a declared custom item), and all three
// per-mob handlers. lost_sheep: passive mob with a vanilla-only drop.

item "rotten_scimitar" {
    material: "GOLDEN_SWORD"
    name: "Rotten Scimitar"
    rarity: uncommon

    // Combat stats are userland data now (phase 9): attach them as NBT tags
    // and read them back from your own damage-event handler.
    tags: {
        damage: 40,
        strength: 10
    }

    lore {
        line "Pried from a ghoul's cold hands."
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

mob "lost_sheep" {
    type: "SHEEP"
    name: "<yellow>Lost Sheep"
    health: 20
    ai: passive

    drops {
        item "MUTTON" chance 1.0 amount 1
    }

    on_death {
        broadcast "<gray>The lost sheep is finally at peace."
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

event MobDeath {
    execute {
        if event.killer exists {
            send "<gold>Kill credit: ${event.mob.custom_id}" to event.killer
        }
    }
}
