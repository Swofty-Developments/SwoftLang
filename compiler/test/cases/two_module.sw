import "./mod/greeter.sw"

command "greet" {
    execute {
        send greet("alex") to sender
        set g to find_greeting("steve")
        if g exists {
            send g to sender
        }
    }
}
