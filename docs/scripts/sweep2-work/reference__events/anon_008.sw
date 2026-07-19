event PickupItem {
    priority: 1

    execute {
        if event.cancelled {
            send "too slow, the catch is gone" to all
        }
        send "caught ${event.item_stack}" to all
    }
}
