command "strings" {
    execute {
        set greeting to "  Hello, World  "
        set clean to greeting.trimmed()
        set up to uppercase of clean
        send "clean '${up}' len ${length of clean}" to sender
    }
}
