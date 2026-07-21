command "string-methods" {
    execute {
        set clean to "Hello, World"
        set parts to clean.split(", ")
        set rep to "ab".repeated(3)
        set starts to clean.starts_with("Hello")
        send "parts ${parts.size}, rep ${rep}, starts ${starts}" to sender
    }
}
