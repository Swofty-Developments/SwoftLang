// v1.9.0 custom mob AI: goals, targets, navigator.

// the preset ai: string form still compiles (sugar over built-in goals)
mob Zombie {
    type: "ZOMBIE"
    health: 20
    ai: melee
}

// reusable named goal TYPE (§3): `mob` binds to the attaching creature
goal Wander {
    on_tick {
        path mob to random_point_near(mob.location, 8)
    }
}

goal FleeFrom {
    should_start { target exists }
    on_tick {
        path mob to random_point_near(mob.location, 6) at speed 0.35
        look at target
    }
    should_end { target is none }
}

// full ai { } block: natural + block targets, inline goals, navigator stmts
mob Guardian {
    type: "IRON_GOLEM"
    health: 100
    ai {
        target closest Player within 16
        target last attacker within 24
        target { return player("Herobrine") }
        goal "chase" {
            should_start { target exists }
            on_start {
                look at target
            }
            on_tick {
                path mob to target
                if distance(mob, target) < 2 {
                    stop pathing mob
                }
                if mob reached target {
                    look at target
                }
            }
            should_end { target is none }
            on_end {
                stop pathing mob
            }
        }
        goal "wander" priority 5 {
            on_tick {
                path mob to random_point_near(mob.location, 8)
                if mob.navigating {
                    look at mob.location
                }
            }
        }
    }
}

// attach reusable goal types by name, with declaration-order + explicit priority
mob Critter {
    type: "RABBIT"
    ai {
        target closest Player within 6
        target closest Guardian within 10
        goals: [ FleeFrom, Wander priority 5 ]
    }
}
