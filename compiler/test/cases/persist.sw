storage {
    backend: files "data/swoftlang"
    flush: every 10 seconds
}

persistent total_joins: Integer = 0
persistent spawn_ratio: Double = 1.5
persistent motd_extra: String = ""
persistent kills for Player: Integer = 0
persistent last_seen for Player: String = "never"
persistent hardcore for Player: Boolean = false

Player {
    on_join {
        set total_joins to total_joins + 1
        set last_seen for player to "today"
        send "Join #${total_joins}${motd_extra}" to player
    }
}

command "kills" {
    execute {
        set kills for sender to kills for sender + 1
        if kills for sender > 10 {
            set hardcore for sender to true
        }
        send "You have ${kills for sender} kill(s), ratio ${spawn_ratio * 2}" to sender
    }
}
