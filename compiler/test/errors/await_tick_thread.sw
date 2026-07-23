async function slow() {
    wait 1 ticks
    return 5
}

Player {
    on_join {
        set x to await spawn slow()
    }
}
