Player {
    on_join() {
        set handle to this.tasks.welcome        // optional<Schedule>
        if this.tasks.welcome exists broadcast "welcome is bound"
    }
}
