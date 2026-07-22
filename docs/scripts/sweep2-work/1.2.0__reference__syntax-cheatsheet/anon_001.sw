command "tp",
command "teleport" {                          // aliases share one body
    permission: "swoftlang.teleport"
    description: "Teleport a player"

    arguments {
        player: Player = sender               // one-token default
        target: either<Player|Location>       // union type, no default
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
