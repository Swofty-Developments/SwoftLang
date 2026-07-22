function find_target(name: String) {
    set found to player(name)
    if found exists {
        return found
    }
}

command "hunt" {
    execute {
        set t to find_target("Herobrine")
        if t exists {
            send "target: ${t.name}" to sender
        } else {
            send "no target" to sender
        }
        set safe to find_target("Herobrine") otherwise sender
        send "safe = ${safe}" to sender
    }
}
