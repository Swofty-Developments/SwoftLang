import "./mod/counterstate.sw"

command "counter" {
    execute {
        claim(sender.name)
        advance()
        send describe() to sender
    }
}
