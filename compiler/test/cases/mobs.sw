item "rotten_scimitar" {
    material: "GOLDEN_SWORD"
    rarity: uncommon
    attributes: {
        attack_damage: 8
    }
}

mob "crypt_ghoul" {
    type: "ZOMBIE"
    name: "<red>Crypt Ghoul <green>${mob.health}<red>!"
    health: 200
    damage: 25
    speed: 0.3
    ai: melee

    drops {
        item "rotten_scimitar" chance 0.05 amount 1
        item "ROTTEN_FLESH" chance 0.5 amount 2
    }

    on_spawn {
        broadcast "<gray>A ${mob.custom_id} rises..."
    }

    on_death {
        if killer exists {
            send "<green>You killed the ghoul!" to killer
        }
    }

    on_attack {
        send "<red>The ghoul strikes you!" to victim
    }
}

mob "harmless_chicken" {
    type: "CHICKEN"
    name: "<yellow>Cluckers"
    health: 10
    ai: passive
}

command "ghoul" {
    execute {
        spawn mob "crypt_ghoul" at location(10, 64, 20) as m
        set m.name to "<red>Angry Ghoul"
        set m.health to m.max_health / 2
        teleport sender to m.location
        loop all_mobs("crypt_ghoul") as g {
            despawn g
        }
    }
}

Mob {
    on_spawn() {
        broadcast "spawned: ${this.type}"
    }

    on_death(killer) {
        if killer exists {
            broadcast "<gold>Kill credit!"
        }
    }

    on_hit(attacker) {
        if this.health < 10 {
            broadcast "<red>the mob is low"
        }
    }
}
