async function ping(mirror: String) {
    wait 100 millis
    return mirror
}

async function fastest(p: Player) {
    set winner to await any of [spawn ping("eu"), spawn ping("us"), spawn ping("asia")]
    send "<lime>fastest mirror: ${winner}" to p
}
