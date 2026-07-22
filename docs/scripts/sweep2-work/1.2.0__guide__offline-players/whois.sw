persistent balance for Player: Integer = 0

command "whois" {
    description: "Look up anyone this server has ever seen"
    arguments {
        who: String
    }
    execute {
        set found to offline_player(args.who)
        if found exists {
            send "<gold>${found.name}</gold> <gray>(${found.uuid})</gray>" to sender
            send "first seen ${found.first_seen}, last seen ${found.last_seen}" to sender
            send "balance: ${balance for found}" to sender
            if found.player exists {
                send "<green>${sender} looked you up!" to found.player
            }
        } else {
            send "never seen anyone called ${args.who}" to sender
        }
    }
}
