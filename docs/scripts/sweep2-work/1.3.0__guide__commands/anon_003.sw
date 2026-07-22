command "heal" {
    permission: "myserver.heal"
    description: "Restore your health to full"

    execute {
        if sender is a Player {
            set sender.health to sender.max_health
            send "<lime>Healed!" to sender
        }
    }
}
