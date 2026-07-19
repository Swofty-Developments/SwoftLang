command "boss" {
    execute {
        spawn mob "gholu" at location(0, 64, 0)
    }
}

mob "ghoul" {
    type: "ZOMBIE"
    health: 100
}
