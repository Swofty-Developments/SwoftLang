Server {
    on_list_ping(status) {
        set status to "<green>${length(all_players())} heroes online right now"
    }
}
