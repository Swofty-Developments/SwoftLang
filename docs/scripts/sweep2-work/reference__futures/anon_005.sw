async function ping(mirror: String) {
    wait 100 millis
    return mirror
}

async function pick(p: Player) {
    set mirrors to [spawn ping("eu"), spawn ping("us"), spawn ping("asia")]
    set all_replies to await all of mirrors     // List<String>, all three
    set first_reply to await any of mirrors     // String, whichever won
    send "${all_replies.size} replied, ${first_reply} first" to p
}
