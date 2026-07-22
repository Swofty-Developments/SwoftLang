command "greet" {
    arguments {
        who: Optional<Player>
    }
    execute {
        set target to args.who otherwise sender
        send "<green>Hello, ${target.name}!" to target
    }
}
