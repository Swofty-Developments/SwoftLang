command "platform" {
    execute {
        fill blocks from location(-5.0, 63.0, -5.0) to location(5.0, 63.0, 5.0) with "SMOOTH_STONE"
        set block at location(0.0, 64.0, 0.0) to "BEACON"
        send "standing on ${block_at(sender.location)}" to sender
    }
}
