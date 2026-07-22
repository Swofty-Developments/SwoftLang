function find_target(name: String) {
    set p to player(name)
    if p exists {
        return p
    }
}

command "opt" {
    description: "option types and narrowing"

    arguments {
        who: Optional<Player>
        dest: Either<Player|Location>=sender
        tags: List<String>
    }

    execute {
        set maybe to player("Notch")
        if maybe exists {
            send "found ${maybe.name}" to sender
        } else {
            send "nobody home" to sender
        }

        set target to maybe otherwise sender
        send "target is ${target.name}" to sender

        set w to world("lobby")
        if w is missing {
            send "<red>no lobby world" to sender
            halt
        }
        set event_player to none
        set names to ["Alice", "Bob"]
        set count to length(names)
        send "count = ${count}" to sender
        loop names as n {
            send "name: ${n}" to sender
        }
        loop first 1 of names as n {
            send "first: ${n}" to sender
        }

        if args.who exists {
            teleport args.who to sender
        }

        if args.dest is a Player {
            send "dest is a player" to sender
        } else {
            teleport sender to args.dest
        }

        set ft to find_target("Steve")
        if ft exists {
            send "ft = ${ft.name}" to sender
        }
        set fallback to find_target("Alex") otherwise sender
        send "fallback = ${fallback.name}" to sender
    }
}
