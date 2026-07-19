event PlayerStartSprinting {
    execute {
        send "${event.player.name} sprints" to event.player
    }
}
