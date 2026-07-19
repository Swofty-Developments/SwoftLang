event PlayerChat {
    execute {
        async {
            wait 5 ticks
            cancel event
        }
    }
}
