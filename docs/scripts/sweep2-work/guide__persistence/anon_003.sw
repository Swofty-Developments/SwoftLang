persistent kills for Player: Integer = 0
persistent last_seen for Player: String = "never"

Player {
    on_join {
        send "kills on record: ${kills for player}" to player
        set last_seen for player to "today"
    }
}
