command "modcheck" {
    execute {
        if has_permission(sender, "swoftlang.moderate") {
            send "<green>You may moderate." to sender
        } else {
            send "<red>You may not." to sender
        }
    }
}
