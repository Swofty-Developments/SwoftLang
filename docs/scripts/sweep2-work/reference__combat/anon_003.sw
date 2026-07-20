command "smite" {
    execute {
        damage sender by 6.0 as "magic"
        apply "regeneration" 1 to sender for 100
        shoot "arrow" from sender.location with velocity velocity(0, 1, 2) by sender
    }
}
