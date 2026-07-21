persistent kills for Player: Integer = 0
persistent last_seen for Player: String = "never"

Player {
    on_join() {
        send "kills on record: ${kills for this}" to this
        set last_seen for this to "today"
    }
}
