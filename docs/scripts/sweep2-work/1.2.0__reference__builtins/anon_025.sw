Item {
    on_use(player) {
        if custom_id(this) otherwise "" is "cookie_of_truth" {
            send "<gold>It tastes... honest." to player
        }
    }
}

item "cookie_of_truth" {
    material: "COOKIE"
    name: "Cookie of Truth"
    rarity: rare
}
