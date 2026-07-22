mob CryptGhoul {
    type: "ZOMBIE"
    name: "<red>Crypt Ghoul <green>${mob.health}<red>❤"
    health: 200
    damage: 25
    speed: 0.3
    ai: melee

    drops {
        item "ROTTEN_FLESH" chance 0.5 amount 2
    }

    on_death {
        if killer exists {
            send "<green>You slew the Crypt Ghoul!" to killer
        }
    }
}

command "ghoul" {
    execute {
        spawn mob CryptGhoul at location(10, 64, 20) as m
        set m.health to m.max_health / 2
        send "<gray>Spawned ${m.custom_id} at half health." to sender
    }
}
