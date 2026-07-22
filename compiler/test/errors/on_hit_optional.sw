// on_hit binds attacker as optional<Player>; it must be narrowed
// before it flows into a place that needs a present Player.
mob Brute {
    type: "ZOMBIE"
    on_hit {
        send "ouch" to attacker
    }
}
