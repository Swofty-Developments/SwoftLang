import "./mod/privlib.sw"

command "peek" {
    execute {
        send hidden_helper() to sender
    }
}
