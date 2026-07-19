persistent total_joins: Integer

command "joins" {
    execute {
        send "${total_joins}" to sender
    }
}
