event ServerPing {
    execute {
        set event.motd to "<green>${length(all_players())} heroes online right now"
        set event.max to 1000
    }
}
