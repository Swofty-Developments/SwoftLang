item "shiny_pebble" {
    material: "STONE"
}

mob "generous_ghoul" {
    type: "ZOMBIE"
    health: 10
    drops {
        item "shiny_pebble" chance 5.0 / 2.0 amount 1
    }
}
