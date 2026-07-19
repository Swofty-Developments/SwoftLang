async function slow() {
    wait 1 seconds
}

command "sync" {
    execute {
        slow()
    }
}
