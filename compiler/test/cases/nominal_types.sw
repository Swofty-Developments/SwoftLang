// §2 nominal custom types: mob/item declarations are Capitalized nominal types
// with a separate stable string id (explicit `id:` or snake_case of the name).

mob Ghoul {
    // id omitted -> defaults to snake_case("Ghoul") = "ghoul"
    type: "ZOMBIE"
    health: 40
    on_hit {
        set mob.health to mob.health - 1
    }
}

mob AncientGuardian {
    id: "guardian_boss"          // explicit stable id, pinned
    type: "ELDER_GUARDIAN"
    health: 200
}

item AspectOfTheEnd {
    // id omitted -> defaults to "aspect_of_the_end"
    material: "DIAMOND_SWORD"
    name: "Aspect of the End"
    on_right_click {
        send "woosh" to player
    }
}

// custom type usable as a parameter type (nominal subtype of Mob)
function empower(g: Ghoul) {
    set g.health to 100
}

// a plain Mob parameter accepts a Ghoul too (normal subtyping)
function announce(m: Mob) {
    broadcast "a mob stirs"
}

Player {
    on_join {
        // spawn by type: compile-checked, binding is x : Ghoul
        spawn mob Ghoul at location(0, 100, 0) as boss
        set boss.health to 50
        empower(boss)         // Ghoul -> Ghoul
        announce(boss)        // Ghoul -> Mob (subtyping)

        // string-id API still takes the id string, unchanged
        give item "aspect_of_the_end" to player

        // dynamic, data-driven spawn by id -> base Mob
        spawn mob by id "ghoul" at location(0, 100, 0) as dyn
        announce(dyn)

        // is a Ghoul narrows dyn (a Mob) to Ghoul in the block
        if dyn is a Ghoul {
            empower(dyn)
        }
    }
}
