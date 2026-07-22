storage {
    backend: sqlite "data/homes.db"
    flush: every 10 seconds
}

persistent home for Player: Optional<Location> = none
persistent kit for Player: List<Item> = []

command "sethome" {
    description: "Save your current spot as home"
    execute {
        if sender is a Player {
            set home for sender to sender.location
            send "<green>Home saved." to sender
        }
    }
}

command "home" {
    description: "Teleport to your saved home"
    execute {
        if sender is a Player {
            set spot to home for sender
            if spot exists {
                teleport sender to spot
                send "<gray>Welcome home." to sender
            } else {
                send "<red>You haven't set a home yet." to sender
            }
        }
    }
}

command "savekit" {
    description: "Remember your held item as your kit"
    execute {
        if sender is a Player {
            set kit for sender to [sender.held_item]
            send "<green>Kit saved (${length(kit for sender)} items)." to sender
        }
    }
}

command "loadkit" {
    execute {
        if sender is a Player {
            loop kit for sender as piece {
                set sender.held_item to piece
            }
        }
    }
}
