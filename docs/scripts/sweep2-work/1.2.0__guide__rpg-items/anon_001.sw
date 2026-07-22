command "inspect-sword" {
    execute {
        set sword to custom_item("aspect_of_the_end")

        // tag reads are optional<Any> — give each a fallback
        set dmg to sword.tags.damage otherwise 0
        set str to sword.tags.strength otherwise 0
        set tier to sword.tags.tier otherwise "COMMON"

        // one source of truth: the same numbers the lore displays
        set effective to dmg + str / 2
        send "<gray>${tier} sword — effective damage ${effective}" to sender
    }
}
