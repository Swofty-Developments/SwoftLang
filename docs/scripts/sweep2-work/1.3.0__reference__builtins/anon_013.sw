command "parsing" {
    execute {
        set n to parse("42", Integer) otherwise 0             // 42
        if matches("abc123", "[a-z0-9]+") {
            send "valid handle" to sender
        }
        send stripped("&aHello") to sender                    // Hello
        send formatted("&aHello") to sender                   // green Hello
        send "n is a ${type_of(n)}" to sender                 // Integer
    }
}
