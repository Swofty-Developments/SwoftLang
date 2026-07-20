command "bigfill" {
    execute {
        // compiles, but earns the warning above
        fill blocks from location(0.0, 0.0, 0.0) to location(99.0, 99.0, 99.0) with "STONE"
    }
}
