// v1.10.0 §4: declaration-attached change events. The storage block is the
// DEFAULT (mode: standalone), which also pins the invariant that on_change works
// there — it fires locally and caused_here is always true.

storage {
    backend: files "data/game"
    flush: every 10 seconds
}

// a scalar global: bound old, new, caused_here
persistent boss_active: Boolean = false {
    on_change {
        if new {
            broadcast "<red>The world boss has awoken!"
        } else {
            broadcast "<gray>The world boss is gone (was ${old})"
        }
    }
}

// per-player: the declaration's key binds as 'player'
persistent coins for Player: Integer = 0 {
    on_change {
        send "<gold>${old} -> ${new} coins" to player
        // caused_here guard: only the server that made the write announces it
        if caused_here {
            broadcast "<yellow>${player.name} now has ${new} coins"
        }
        // §5.2 exception: the SAME value at a DIFFERENT key is allowed — this is
        // a referral bonus, not a self re-fire, and the runtime depth cap bounds
        // it
        loop all players as other {
            grant 1 coins to other
        }
    }
}

// keyed global: the declaration's key binds as 'key'
persistent scores for String: Integer = 0 {
    on_change {
        broadcast "<aqua>${key}: ${old} -> ${new}"
    }
}

// a collection reacts per ENTRY, with Optional old/new
persistent leaderboard: Map<String, Integer> = new_map() {
    on_entry_change {
        if old is missing {
            broadcast "<green>${key} joined at ${new otherwise 0}"
        } else if new is missing {
            broadcast "<gray>${key} fell off"
        } else {
            broadcast "<gold>${key} -> ${new otherwise 0}"
        }
    }
}

// a value with no handler at all: unchanged emission
persistent pot: Integer = 0

command "econ" {
    execute {
        set boss_active to true
        set coins for sender to (coins for sender) + 5
        set scores for sender.name to 1
        set leaderboard at sender.name to 10
        set pot to pot + 1
    }
}
