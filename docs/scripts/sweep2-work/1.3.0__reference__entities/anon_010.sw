mob "sentinel" {
    type: "IRON_GOLEM"
    viewable: false
}

command "audience" {
    execute {
        spawn mob "sentinel" at in_front_of(sender, 3) as g
        show g to sender
        loop viewers of g as watcher {
            send "<gray>${watcher.name} can see the sentinel" to watcher
        }
        send "<yellow>viewers: ${length(viewers of g)}" to sender
    }
}
