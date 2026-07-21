// Fixture for MobOverrideSmoke: proves the OOP override dispatch for a mob's
// DEDICATED on_hit / on_death fields (parse_content dedicated path), i.e. that
// default() inside an overriding mob handler chains into the base Mob.<method>
// and that most-specific-wins suppresses the base receiver event otherwise.
//
// Every marker is delivered with `send ... to <player>` (the only sink a
// headless fake player captures); the shared, single-threaded executor makes
// the packet order the true firing order, so "B THEN A" is directly asserted.

// Base receiver: fires for every mob instance (via MobDamage) unless a more
// specific custom declaration overrides it. Uses `this.custom_id`, so any run
// of this body (directly, or via an override's default()) proves `this` = the
// acted-on mob was threaded through.
Mob {
    on_hit(attacker) {
        if attacker is a Player {
            send "TRACE=BASE_A:${this.custom_id}" to attacker
        }
    }
}

// A plain mob: no custom on_hit -> only the base runs.
mob "critter" {
    type: "CHICKEN"
    health: 10
}

// Overrides on_hit and calls default(): B then (via default) the base A, once.
mob "ghoul_d" {
    type: "ZOMBIE"
    health: 40

    on_hit(attacker) {
        if attacker exists {
            send "TRACE=CUST_B:${mob.custom_id}" to attacker
        }
        default()
    }
}

// Overrides on_hit and does NOT call default(): base is suppressed.
mob "ghoul_n" {
    type: "ZOMBIE"
    health: 40

    on_hit(attacker) {
        if attacker exists {
            send "TRACE=CUST_ONLY:${mob.custom_id}" to attacker
        }
    }
}

// Overrides on_death (a dedicated field) but the base declares NO on_death, so
// default() must be a safe no-op.
mob "ghoul_x" {
    type: "ZOMBIE"
    health: 40

    on_death {
        if killer exists {
            send "TRACE=NOBASE_DEATH:${mob.custom_id}" to killer
        }
        default()
    }
}
