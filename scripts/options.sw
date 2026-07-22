function find_target(name: String) {
    set found to player(name)
    if found exists {
        return found
    }
}

function describe(dest: Either<Player|Location>) {
    if dest is a Player {
        return "a player"
    } else {
        return "a location at x=${dest.x}"
    }
}

command "options" {
    description: "Showcase of option types, narrowing and otherwise chains"

    arguments {
        who: Optional<Player>
    }

    execute {
        // optional builtin result + exists narrowing (both branches)
        set missing_player to player("Notch")
        if missing_player exists {
            send "found ${missing_player.name}"
        } else {
            send "nobody called Notch here"
        }
        if missing_player is missing {
            send "confirmed: still missing"
        }

        // none literal + otherwise fallback
        set label to none
        set title to label otherwise "guest"
        send "title = ${title}"

        // otherwise chains: first present value wins
        set fallback to player("Alex") otherwise player("Steve") otherwise "console"
        send "fallback = ${fallback}"

        // optional command argument
        if args.who exists {
            send "who = ${args.who.name}"
        } else {
            send "no who argument supplied"
        }

        // either narrowing via is a (else-branch knows it is a Location)
        set where to describe(location(0.5, 64.0, 0.5))
        send "spawn is ${where}"

        // mixed-return function types as Optional<Player>
        set target to find_target("Herobrine")
        if target exists {
            send "target found"
        } else {
            send "no target - falling back"
        }
        set safe to find_target("Herobrine") otherwise sender
        send "safe = ${safe}"
    }
}
