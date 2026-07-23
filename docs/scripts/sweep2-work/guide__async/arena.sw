struct Loadout { name: String }
struct MatchStats { wins: Integer }

async function load_loadout(p: Player) {
    wait 400 millis
    return Loadout { name: "Vanguard" }
}

async function load_stats(p: Player) {
    wait 700 millis
    return MatchStats { wins: 12 }
}

async function enter_arena(p: Player) {
    // fire both loads off in parallel — the vthreads work while we count down
    set loadout_job to spawn load_loadout(p)
    set stats_job to spawn load_stats(p)

    loop 3 times as i {
        send "<yellow>Entering the arena in ${3 - i}..." to p
        wait 1 seconds
    }

    // the countdown outlasted both loads; await just collects what's ready
    set (loadout, stats) to await all of [loadout_job, stats_job]
    send "<lime>Welcome, ${loadout.name} — ${stats.wins} career wins" to p
}

command "arena" {
    execute {
        if sender is a Player {
            spawn enter_arena(sender)
        }
    }
}
