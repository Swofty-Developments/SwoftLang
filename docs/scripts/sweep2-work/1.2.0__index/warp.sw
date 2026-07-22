command "warp" {
    description: "Send someone to spawn"

    arguments {
        who: optional<Player>
    }

    execute async {
        set target to args.who otherwise sender
        send "<gray>Warping ${target.name} in 3 seconds..." to target
        wait 3 seconds
        teleport target to location(0.5, 64.0, 0.5)
        send "<green>Welcome to spawn, ${target.name}!" to target
    }
}
