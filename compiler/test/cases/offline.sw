// Phase-8 offline players: seen-store lookups, the OfflinePlayer property
// rows, Player <: OfflinePlayer subtyping, '.player exists' narrowing, and
// player-keyed persistents taking either subject (uuid identity).

persistent coins for Player: Integer = 0
persistent visits for OfflinePlayer: Integer = 0

command "seen" {
    arguments {
        who: String
    }
    execute {
        set found to offline_player(args.who)
        if found exists {
            send "${found.name} (${found.uuid})" to sender
            send "first seen ${found.first_seen}, last seen ${found.last_seen}" to sender
            if found.online {
                send "online right now" to sender
            }
            if found.has_played_before {
                send "a returning player" to sender
            }
            if found.player exists {
                teleport sender to found.player
                send "warped to you!" to found.player
            }
            set visits for found to visits for found + 1
            set coins for found to coins for found + 10
        } else {
            send "never seen ${args.who}" to sender
        }
    }
}

command "seenall" {
    execute {
        loop all_seen_players() as p {
            send "${p.name}: ${p.uuid}" to sender
        }
        set fixed to offline_player_uuid("069a79f4-44e9-4726-a5be-fca90e38aaf5")
        send "record for ${fixed.name}" to sender
        set coins for fixed to 5
        set visits for sender to visits for sender + 1
    }
}

command "lookup" {
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

function greet(target: OfflinePlayer) {
    if target is a Player {
        send "welcome back!" to target
    }
}

Player {
    on_join() {
        if this is a OfflinePlayer {
            send "you are also a seen-store record" to this
        }
        greet(this)
    }
}
