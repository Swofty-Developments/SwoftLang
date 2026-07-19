persistent kills for Player: Integer = 0
persistent last_seen for Player: String = "never"

event PlayerJoin {
    execute {
        send "kills on record: ${kills for event.player}" to event.player
        set last_seen for event.player to "today"
    }
}
