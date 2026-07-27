// v1.10.0 §1: the STANDALONE twin of net_persist.sw. Byte-for-byte the same
// declarations and the same statements — only the storage block differs. Every
// atomic op is a plain local mutation here and every network typing rule is
// off, which is the property that lets you develop standalone and flip to
// network at deploy time.

storage {
    backend: files "data/swoftlang"
    flush: every 30 seconds
}

// replicated globals: no 'for', or keyed by String / Integer
persistent pot: Integer = 0
persistent boss_active: Boolean = false
persistent announcements: List<String> = []
persistent leaderboard: Map<String, Integer> = new_map()
persistent scores for String: Integer = 0
persistent visits for Integer: Integer = 0

// session-owned: keyed by Player / OfflinePlayer
persistent coins for Player: Integer = 0
persistent history for OfflinePlayer: List<String> = []

Player {
    on_join {
        // the subject is a live Player, so this server owns it: sync read AND
        // sync read-modify-write, exactly as in standalone
        set coins for player to (coins for player) + 10
        send "You have ${coins for player} coins" to player

        // replicated globals: atomic writes only
        add 50 to pot
        subtract 5 from pot
        set boss_active to true
        append "a player joined" to announcements
        set leaderboard at player.name to coins for player

        // an unconditional set of a keyed global is last-writer-wins, fine
        set scores for "global" to 1
        set visits for 1 to 2
    }
}

function reward(who: OfflinePlayer) {
    // an OfflinePlayer may be on another server: atomic ops only
    grant 100 coins to who
    append "was-rewarded" to history for who

    async {
        // ...and the read is a Future<Integer>, so it must be awaited
        set bal to await coins for who
        broadcast "balance is ${bal}"
    }
}
