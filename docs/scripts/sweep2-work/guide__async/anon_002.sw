command "heal" {
    execute async {
        send "<gray>Healing in 5 seconds..." to sender
        wait 5 seconds
        if sender is a Player {
            set sender.health to sender.max_health
        }
        send "<green>Healed!" to sender
    }
}
