command "x" {
    execute {
        spawn entity "ARMOR_STAND" at location(0, 64, 0) as e
        set e.pose to "flying"
    }
}
