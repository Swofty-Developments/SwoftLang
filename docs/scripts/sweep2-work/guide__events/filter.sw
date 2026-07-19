event PlayerChat {
    execute async {
        wait 1 ticks
        cancel event
    }
}
