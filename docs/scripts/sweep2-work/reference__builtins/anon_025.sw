event PlayerUseItem {
    execute {
        if custom_id(event.item) otherwise "" is "cookie_of_truth" {
            send "<gold>It tastes... honest." to event.player
        }
    }
}

item "cookie_of_truth" {
    material: "COOKIE"
    name: "Cookie of Truth"
    rarity: rare
}
