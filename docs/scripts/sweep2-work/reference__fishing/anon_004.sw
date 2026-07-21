Player {
    on_cast_rod() {
        if this.world.time > 100000 {
            send "<gray>The fish are asleep." to this
        }
    }
}
