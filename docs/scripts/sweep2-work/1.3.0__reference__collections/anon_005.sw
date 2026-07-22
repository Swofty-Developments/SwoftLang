command "strings" {
    execute {
        set greeting to "  Hello, World  "
        set clean to greeting.trimmed()
        set parts to clean.split(", ")
        set up to clean.upper()
        set rep to "ab".repeated(3)
        set starts to clean.starts_with("Hello")
        send "clean '${up}' len ${clean.length()}" to sender
        send "parts ${parts.size}, rep ${rep}, starts ${starts}" to sender
    }
}
