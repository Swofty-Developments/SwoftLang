command "tilt" {
    execute {
        set d to spawn_block_display("GRASS_BLOCK", location(0.5, 65.0, 0.5))
        set d.rotation to location(0.0, 45.0, 0.0)      // 45° around Y
        set d.translation to location(0.0, 0.25, 0.0)   // raised a quarter block
    }
}
