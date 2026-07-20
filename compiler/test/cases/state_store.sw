// W-pvp per-entity in-memory state store: set_state / get_state / has_state /
// clear_state. get_state flows to optional<Any> (integrates with otherwise);
// has_state is a Boolean; set_state / clear_state are used as statements.

command "state" {
    execute {
        set_state(sender, "iframe", 10)
        set_state(sender, "last_hit", "sword")

        if has_state(sender, "iframe") {
            set ticks to get_state(sender, "iframe") otherwise 0
            send "iframe = ${ticks}" to sender
        }

        set weapon to get_state(sender, "last_hit") otherwise "fist"
        send "weapon = ${weapon}" to sender

        clear_state(sender, "iframe")

        // works over any live entity, not just players
        loop all_entities() as e {
            set_state(e, "seen", true)
            if has_state(e, "seen") {
                clear_state(e, "seen")
            }
        }
    }
}
