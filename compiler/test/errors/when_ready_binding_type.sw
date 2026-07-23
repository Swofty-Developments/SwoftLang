async function load_count(p: Player) {
    wait 1 ticks
    return 5
}

Player {
    on_join {
        when spawn load_count(player) is ready as count {
            send "hello" to count
        }
    }
}
