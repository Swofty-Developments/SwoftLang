Entity {
    on_hit {
        if entity.type is "SHEEP" {
            cancel event                    // sheep take no damage
        }
    }
}
