// on_teleport is an Entity method, not a Player method — receiver method names
// are validated against each receiver's fixed table.
Player {
    on_teleport() {
        broadcast "hi"
    }
}
