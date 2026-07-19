// Downcast narrowing (phase 7): an Entity value narrows to the tested
// runtime subtype in the positive branch — the all_entities() pattern.

command "downcast" {
    execute {
        loop all_entities() as e {
            if e is a Player {
                send "hello player" to e
            }
            if e is a Mob {
                set e.health to 5.0
            }
            if e is not a Player {
                // negative branch keeps Entity
                set e.glowing to true
            } else {
                send "still a player" to e
            }
        }
    }
}
