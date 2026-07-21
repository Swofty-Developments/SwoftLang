// Phase-8 offline players showcase: the seen-store, OfflinePlayer property
// rows, Player <: OfflinePlayer subtyping, the '.player exists' bridge back
// to a live Player, and player-keyed persistents accepting either subject.

storage {
    backend: files "data/swoftlang"
    flush: every 10 seconds
}

// Both spellings key by uuid, so a row written through a Player subject
// reads back through an OfflinePlayer subject with the same uuid.
persistent balance for Player: Integer = 100
persistent visits for OfflinePlayer: Integer = 0

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
            if found.has_played_before {
                send "a returning player" to sender
            }
            if found.online {
                send "currently online" to sender
            }
            // THE bridge: a live Player when they are online, none otherwise
            if found.player exists {
                send "<green>${sender} looked you up!" to found.player
            }
            send "balance ${balance for found}, visits ${visits for found}" to sender
        } else {
            send "never seen anyone called ${args.who}" to sender
        }
    }
}

command "census" {
    description: "Walk every player the seen-store knows"
    execute {
        set seen to 0
        loop all_seen_players() as p {
            set seen to seen + 1
            send "${p.name} <gray>last seen ${p.last_seen}</gray>" to sender
        }
        send "${seen} player(s) on record" to sender

        // total by construction: identity from the uuid, name from the
        // store when known, "unknown" otherwise
        set fixed to offline_player_uuid("069a79f4-44e9-4726-a5be-fca90e38aaf5")
        send "uuid lookup resolves to ${fixed.name}" to sender
        set visits for fixed to visits for fixed + 1
    }
}

command "reward" {
    description: "Pay a player whether or not they are online"
    arguments {
        who: String
        amount: Integer
    }
    execute {
        set target to offline_player(args.who)
        if target exists {
            set balance for target to balance for target + args.amount
            send "paid ${args.amount} to ${target.name}" to sender
            if target.player exists {
                send "<green>+${args.amount} coins!" to target.player
            }
        } else {
            send "no record of ${args.who}" to sender
        }
    }
}

command "lookup" {
    description: "Resolve a Mojang account even if never seen here"
    arguments {
        who: String
    }
    execute async {
        set fetched to fetch_offline_player(args.who)
        if fetched exists {
            send "${fetched.name} = ${fetched.uuid}" to sender
        } else {
            send "no Mojang account named ${args.who}" to sender
        }
    }
}

// Player is an OfflinePlayer: every OfflinePlayer row (and any function
// taking one) accepts a live Player directly.
function describe(subject: OfflinePlayer) {
    if subject is a Player {
        send "you are online right now" to subject
    }
}

Player {
    on_join() {
        describe(this)
        set visits for this to visits for this + 1
    }
}
