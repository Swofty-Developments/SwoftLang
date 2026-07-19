// in_front_of(player, distance) requires two arguments.
command "front" {
    execute {
        set loc to in_front_of(sender)
        teleport sender to loc
    }
}
