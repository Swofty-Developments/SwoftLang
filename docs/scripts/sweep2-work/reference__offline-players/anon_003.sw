command "lookup" {
    arguments {
        who: String
    }
    execute async {
        set fetched to fetch_offline_player(args.who)
        if fetched exists {
            send "${fetched.name} = ${fetched.uuid}" to sender
        } else {
            send "no Mojang account named ${args.who}" to sender
        }
    }
}
