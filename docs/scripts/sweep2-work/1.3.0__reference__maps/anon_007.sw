storage {
    backend: files "data/stash"
    flush: every 10 seconds
}

persistent stash: map<String> = new_map()

command "stow" {
    execute {
        map_set(stash, sender.name, to_nbt(sender.held_item))
        send "stowed your held item" to sender
    }
}

command "recall" {
    execute {
        set raw to stash[sender.name]
        if raw exists {
            set restored to from_nbt(raw)
            if restored exists {
                send "you stowed ${restored.material} x${restored.amount}" to sender
            }
        } else {
            send "nothing stowed" to sender
        }
    }
}
