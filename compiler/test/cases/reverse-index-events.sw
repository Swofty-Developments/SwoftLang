// Reverse index: a receiver method carries the curated identifier the runtime
// binds by (EventType.fromIdentifier). on_break_block/on_place_block emit the
// curated "BlockBreak"/"BlockPlace" names, on_list_ping the "ServerPing" name.

Player {
    on_break_block(block, location, face) {
        send "broke ${block} at ${location.block_x}" to this
        cancel event
    }

    on_place_block(block, location, face, hand) {
        send "placed ${block}" to this
        cancel event
    }
}

Server {
    on_list_ping(status) {
        broadcast "pinged"
    }
}
