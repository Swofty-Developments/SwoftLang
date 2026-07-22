command "snippetwrap" {
    execute {
        spawn entity "ARMOR_STAND" at location(0.5, 64.0, 0.5) as stand
        set stand.location to location(4.5, 65.0, 4.5)
        if stand.alive and not stand.removed {
            send "statue stands at x=${stand.location.x}" to all
        }
    }
}
