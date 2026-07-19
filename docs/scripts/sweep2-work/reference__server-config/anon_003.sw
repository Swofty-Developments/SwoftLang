server {
    permissions {
        "Swofty": ["swoftlang.admin", "swoftlang.teleport"]
    }
}

command "sudo" {
    permission: "swoftlang.admin"
    execute {
        send "<red>with great power..." to sender
    }
}
