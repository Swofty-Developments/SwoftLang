npc "guide" {
    location: location(5, 64, 5)
    skin: "Notch"
}

command "reassign" {
    execute {
        set npc "guide" skin "Herobrine"
        set npc "guide" name "<red>Renamed Guide"
        set npc "guide" location location(6, 64, 6)
    }
}
