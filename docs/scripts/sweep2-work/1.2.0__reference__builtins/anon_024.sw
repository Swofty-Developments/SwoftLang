item "cookie_of_truth" {
    material: "COOKIE"
    name: "Cookie of Truth"
    rarity: rare
}

command "cookie" {
    execute {
        set sender.held_item to custom_item("cookie_of_truth")
    }
}
