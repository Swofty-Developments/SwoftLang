// W-tasks: .tasks is rejected on an Item — items are value types with no stable
// runtime identity, so they carry no per-object task registry.
Player {
    on_join() {
        set this.held_item.tasks.ping to schedule every 20 ticks {
            broadcast "tick"
        }
    }
}
