persistent total: Integer = 0

command "add" {
    arguments {
        total: Integer
    }

    execute {
        send "Total is ${total}" to sender
    }
}
