event ServerPing {
    execute {
        set event.motd to "<green>${length(all_players())} adventurers online"
        set event.max to 1000
    }
}
