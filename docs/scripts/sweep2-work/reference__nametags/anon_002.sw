command "spy" {
    arguments {
        target: Player
    }
    execute {
        // only the command sender sees the mark
        set nametag suffix of args.target to " <dark_red>☠" for sender
        send "<gray>Marked ${args.target.name} — only you see it." to sender
    }
}
