hologram "shop" {
    location: location(0, 82, 0)
    lines {
        line "<gold><bold>Item Shop"
        line "<gray>open"
    }
}

command "closeshop" {
    execute {
        set hologram "shop" line 1 to "<red>closed for maintenance"
        move hologram "shop" to location(2, 82, 0)
        show hologram "shop" to all
    }
}
