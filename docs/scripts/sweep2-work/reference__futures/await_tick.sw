async function score(p: Player) {
    wait 50 millis
    return 10
}

Player {
    on_join {
        set s to await spawn score(player)
        send "score ${s}" to player
    }
}
