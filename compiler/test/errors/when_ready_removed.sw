async function load_stats(p: Player) {
    wait 1 ticks
    return 5
}

Player {
    on_join {
        when spawn load_stats(player) is ready as count {
            send "loaded ${count}" to player
        }
    }
}
