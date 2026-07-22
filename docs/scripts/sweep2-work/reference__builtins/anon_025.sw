Item {
    on_use {
        if custom_id(item) otherwise "" is "cookie_of_truth" {
            send "<gold>It tastes... honest." to player
        }
    }
}

item CookieOfTruth {
    material: "COOKIE"
    name: "Cookie of Truth"
    rarity: rare
}
