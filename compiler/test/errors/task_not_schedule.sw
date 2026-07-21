// W-tasks: a task value must be a Schedule expression; assigning a non-Schedule
// (here an Integer) is a type error.
Player {
    on_join() {
        set this.tasks.bad to 5
    }
}
