on PlayerJoin {
    set handle to event.player.tasks.welcome        // optional<Schedule>
    if event.player.tasks.welcome exists broadcast "welcome is bound"
}
