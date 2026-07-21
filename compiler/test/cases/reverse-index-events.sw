// Reverse index: a receiver method carries the curated identifier the runtime
// binds by (EventType.fromIdentifier). on_break_block/on_place_block emit the
// curated "BlockBreak"/"BlockPlace" names, on_list_ping the "ServerPing" name.

Player {
    on_break_block {
        send "broke ${block} at ${location.block_x}" to player
        cancel event
    }

    on_place_block {
        send "placed ${block}" to player
        cancel event
    }
}

Server {
    on_list_ping {
        broadcast "pinged"
    }
}
