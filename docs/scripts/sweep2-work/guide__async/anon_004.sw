async function delayed_reward(p: Player) {
    wait 30 seconds
    if p.online {
        set p.health to p.max_health
        send "<lime>Reward!" to p
    }
}

command "reward" {
    execute {
        spawn delayed_reward(sender)
    }
}
