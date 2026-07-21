Player {
    on_join {
        set handle to player.tasks.welcome        // optional<Schedule>
        if player.tasks.welcome exists broadcast "welcome is bound"
    }
}
