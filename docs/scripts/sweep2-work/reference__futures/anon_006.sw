struct Stats { kills: Integer }
struct Friends { count: Integer }

async function load_stats(p: Player) {
    wait 300 millis
    return Stats { kills: 12 }
}

async function load_friends(p: Player) {
    wait 500 millis
    return Friends { count: 7 }
}

async function open_menu(p: Player) {
    set (stats, friends) to await all of [spawn load_stats(p), spawn load_friends(p)]
    send "${stats.kills} kills · ${friends.count} friends" to p
}
