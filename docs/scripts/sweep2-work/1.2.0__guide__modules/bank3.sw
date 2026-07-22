import "economy"

command "x" {
    execute {
        send "hi" to sender
    }
}
