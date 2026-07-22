command "snippetwrap" {
    execute {
        spawn entity "ARMOR_STAND" at location(0.5, 64.0, 0.5) as stand
        set stand.velocity to velocity(0.0, 0.5, 0.0)
        set stand.velocity.y to 1.0
    }
}
