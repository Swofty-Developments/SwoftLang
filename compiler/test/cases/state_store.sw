// Per-entity freeform state via the unified `.tags` namespace. Player is an
// Entity, so player.tags.<key> reads flow to optional<Any> (integrating with
// otherwise), `... exists` is a Boolean, and `set ... to none` deletes — the
// same shape as entity/mob tags.

command "state" {
    execute {
        set sender.tags.iframe to 10
        set sender.tags.last_hit to "sword"

        if (sender.tags.iframe exists) {
            set ticks to sender.tags.iframe otherwise 0
            send "iframe = ${ticks}" to sender
        }

        set weapon to sender.tags.last_hit otherwise "fist"
        send "weapon = ${weapon}" to sender

        set sender.tags.iframe to none

        // works over any live entity, not just players
        loop all_entities() as e {
            set e.tags.seen to true
            if (e.tags.seen exists) {
                set e.tags.seen to none
            }
        }
    }
}
