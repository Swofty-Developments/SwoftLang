persistent total_joins: Integer = 0

Player {
    on_join {
        set total_joins to total_joins + 1
        broadcast "<green>${player.name} is join #${total_joins}"
    }
}
