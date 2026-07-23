async function build_profile(p: Player) {
    wait 100 millis
    return "gold"
}

async function demo(player: Player) {
    set handle to spawn build_profile(player)   // Future<String>
    set rank to await handle
    send "rank ${rank}" to player
}
