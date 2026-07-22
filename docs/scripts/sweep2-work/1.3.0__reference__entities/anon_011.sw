command "ghost" {
    execute {
        spawn entity "ARMOR_STAND" at in_front_of(sender, 2) as ghost
        set ghost.name_visible to true
        set name of ghost to "<gray>only you see me" for sender
        show ghost to sender
    }
}
