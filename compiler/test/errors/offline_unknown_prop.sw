command "hp" {
    execute {
        set op to offline_player_uuid("069a79f4-44e9-4726-a5be-fca90e38aaf5")
        send "${op.health}" to sender
    }
}
