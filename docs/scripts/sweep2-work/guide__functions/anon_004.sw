function greet(p: Player) {
    send "Welcome, ${p}!" to p
}

command "greet" {
    execute {
        greet(sender)
        call greet(sender)
    }
}
