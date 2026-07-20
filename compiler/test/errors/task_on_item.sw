// W-tasks: .tasks is rejected on an Item — items are value types with no stable
// runtime identity, so they carry no per-object task registry.
on PlayerJoin {
    set event.player.held_item.tasks.ping to schedule every 20 ticks {
        broadcast "tick"
    }
}
