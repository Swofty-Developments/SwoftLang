command "ab" {
    execute {
        actionbar "<aqua>boost!" to sender                  // single send (fades ~2s)
        actionbar "<red>${sender.health}❤" to sender for 5 seconds
    }
}
