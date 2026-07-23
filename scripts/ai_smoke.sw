// v1.9.0 custom mob AI — headless smoke (goals, targets, navigator, priority).
// Deterministic fixture for --ai-smoke: no timing, no randomness.

// reusable goal TYPE: exercises GoalTypeRegistry wiring + reload teardown.
goal Idle {
    on_tick {
        stop pathing mob
    }
}

// primary AI mob: a natural closest-Player target + two goals of DIFFERING
// priority. `chase` (declaration-order priority 0) outranks `wander`
// (explicit priority 5), so the group runs chase while its target exists.
mob Hunter {
    type: "ZOMBIE"
    ai {
        target closest Player within 32
        goal "chase" {
            should_start { target exists }
            on_start {
                look at target
            }
            on_tick {
                path mob to target
            }
            should_end { target is none }
        }
        goal "wander" priority 5 {
            on_tick {
                stop pathing mob
            }
        }
    }
}

// block target that returns none => no target this tick; a `target exists`
// goal must NOT start.
mob Blind {
    type: "ZOMBIE"
    ai {
        target { return none }
        goal "seek" {
            should_start { target exists }
            on_tick {
                path mob to target
            }
        }
    }
}
