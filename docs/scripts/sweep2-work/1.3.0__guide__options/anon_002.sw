command "greet" {
    arguments {
        who: optional<Player>
    }
    execute {
        if args.who is missing {
            send "you didn't name anyone" to sender
            halt
        }
        send "hello ${args.who.name}" to sender
    }
}
