command "boss" {
    execute {
        spawn mob Gholu at location(0, 64, 0)
    }
}

mob Ghoul {
    type: "ZOMBIE"
    health: 100
}
