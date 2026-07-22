command "greet" {
    arguments {
        who: optional<Player>
    }
    execute {
        set target to args.who otherwise sender
        send "<green>Hello, ${target.name}!" to target
    }
}
