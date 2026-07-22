command "borrow-skin" {
    arguments {
        victim: String
    }
    execute async {
        set s to fetch_skin(args.victim)
        if s exists {
            set sender.skin to s
            send "<green>You are now wearing ${args.victim}'s skin." to sender
        } else {
            send "<red>No such Minecraft account." to sender
        }
    }
}
