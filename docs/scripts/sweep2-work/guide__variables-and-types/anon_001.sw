command "vars" {
    execute {
        set count to 3
        set pi to 3.14
        set active to true
        set name to "Swofty"
        set spawn to location(0.5, 42.0, 0.5)
        set sword to item("diamond_sword")
        send "${name} has ${count} lives" to sender
    }
}
