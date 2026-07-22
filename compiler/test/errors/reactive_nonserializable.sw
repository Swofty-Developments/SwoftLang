// §4: a struct carrying @EventReceiver fields must be serializable (reactive =>
// persistence-rooted). A non-serializable field (World) is rejected.
struct Room {
    @EventReceiver watcher: Player
    board: World
}
