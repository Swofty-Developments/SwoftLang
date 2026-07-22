async function heal_later(p: Player) {
    wait 5 seconds
    set p.health to p.max_health
}

command "heal" {
    execute {
        if sender is a Player {
            heal_later(sender)
        }
    }
}
