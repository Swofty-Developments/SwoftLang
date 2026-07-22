command "minigame" {
    execute {
        // fresh arena per round: clone the template, play, throw it away
        if world_exists("arena_template", polar_loader("worlds")) {
            clone world "arena_template" to "arena_live" with polar_loader("worlds")
            load world "arena_live" with polar_loader("worlds")
        }
    }
}

command "endgame" {
    execute {
        unload world "arena_live" without saving teleporting players to location(0.5, 82.0, 0.5)
        delete world "arena_live" with polar_loader("worlds")
        send "<green>Arena recycled." to sender
    }
}

command "worlds" {
    execute {
        loop all_worlds(polar_loader("worlds")) as w {
            send "<gray>- ${w}" to sender
        }
    }
}
