command "bad" {
    execute {
        set here to location_of(sender)
        set d to distance(here)
        send "${d}" to sender
    }
}
