command "tab" {
    execute {
        show tablist "lobby" to sender
        hide tablist from sender                              // wipe fakes, reset header/footer
        set tablist header to "<red>Maintenance" for sender   // one-off, until next cycle
        set tablist footer to "<gray>back soon" for all
    }
}
