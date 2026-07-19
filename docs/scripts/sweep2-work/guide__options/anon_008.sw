function describe(dest: either<Player|Location>) {
    if dest is a Player {
        return "the player ${dest.name}"
    } else {
        return "a location at x=${dest.x}"
    }
}

command "describe" {
    execute {
        send describe(sender) to sender
    }
}
