// on_hit(attacker) binds attacker as optional<Player>; it must be narrowed
// before it flows into a place that needs a present Player.
mob "brute" {
    type: "ZOMBIE"
    on_hit(attacker) {
        send "ouch" to attacker
    }
}
