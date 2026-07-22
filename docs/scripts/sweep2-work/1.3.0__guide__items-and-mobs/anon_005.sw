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
