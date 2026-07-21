command "strings" {
    execute {
        set greeting to "  Hello, World  "
        set clean to greeting.trimmed()
        set up to clean.upper()
        send "clean '${up}' len ${clean.length()}" to sender
    }
}
