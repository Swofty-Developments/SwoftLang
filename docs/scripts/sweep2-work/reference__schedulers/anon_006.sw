Player {
    on_join {
        set handle to player.tasks.welcome        // Optional<Schedule>
        if player.tasks.welcome exists broadcast "welcome is bound"
    }
}
