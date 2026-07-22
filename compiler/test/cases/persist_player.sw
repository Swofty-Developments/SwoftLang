storage {
    backend: files "data/swoftlang"
    flush: every 10 seconds
}

persistent team: List<Player> = []
persistent champion: Optional<Player> = none
persistent captains: Map<String, Player> = new_map()

Player {
    on_join {
        add player to team
        set champion to player
        set captains at "red" to player
    }
}
