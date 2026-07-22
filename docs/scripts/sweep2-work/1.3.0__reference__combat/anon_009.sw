every 1 tick {
    loop all_players() as p {
        // starvation: food 0 -> 1 damage every 80 ticks, never below 1 HP
        if p.food <= 0 and p.health > 1.0 {
            set starve_timer to p.tags.starve_timer otherwise 0
            if starve_timer >= 80 {
                damage p by 1.0 as "starve"
                set p.tags.starve_timer to 0
            } else {
                set p.tags.starve_timer to starve_timer + 1
            }
        }
    }
}
