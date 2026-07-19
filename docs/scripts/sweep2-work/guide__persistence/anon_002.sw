persistent total_joins: Integer = 0

event PlayerJoin {
    execute {
        set total_joins to total_joins + 1
        broadcast "<green>${event.player.name} is join #${total_joins}"
    }
}
