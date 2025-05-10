command "hello" {
    permission: "swoftlang.hello"
    description: "Sends a hello message"
    
    execute {
        send "<lime>Hello from SwoftLang" to sender
    }
}

command "teleport" {
    permission: "swoftlang.teleport"
    description: "Teleport a player to coordinates or another player"

    arguments {
        player: Player = sender                   // Default to command sender if not specified
        target: either<Player|Location>           // Can be either a Player or Location, has no default
    }

    execute {
        if args.player is not a Player {
            send "<red>You can only teleport players" to sender
            halt
        }

        teleport args.player to args.target
        send "<lime>Teleported ${sender} to ${args.target}"
    }
}